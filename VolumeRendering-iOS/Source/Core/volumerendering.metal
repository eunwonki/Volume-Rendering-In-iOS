#include <metal_stdlib>
using namespace metal;
#include <SceneKit/scn_metal>

// https://developer.apple.com/documentation/scenekit/scnprogram
//struct SCNSceneBuffer {
//    float4x4    viewTransform;
//    float4x4    inverseViewTransform; // view space to world space
//    float4x4    projectionTransform;
//    float4x4    viewProjectionTransform;
//    float4x4    viewToCubeTransform; // view space to cube texture space (right-handed, y-axis-up)
//    float4      ambientLightingColor;
//    float4      fogColor;
//    float3      fogParameters; // x: -1/(end-start) y: 1-start*x z: exponent
//    float       time;     // system time elapsed since first render with this shader
//    float       sinTime;  // precalculated sin(time)
//    float       cosTime;  // precalculated cos(time)
//    float       random01; // random value between 0.0 and 1.0
//};

struct NodeBuffer {
    float4x4 modelTransform;
    float4x4 inverseModelTransform;
    float4x4 modelViewTransform;
    float4x4 inverseModelViewTransform;
    float4x4 normalTransform;
    float4x4 modelViewProjectionTransform;
    float4x4 inverseModelViewProjectionTransform;
    float2x3 boundingBox;
    float2x3 worldBoundingBox;
};

struct Uniforms {
    int method;
    int renderingQuality;
};

// https://github.com/TwoTailsGames/Unity-Built-in-Shaders
float3 ObjSpaceViewDir(float4 v, NodeBuffer node, SCNSceneBuffer scene)
{
    float4 worldCameraPos = scene.inverseViewTransform * float4(0, 0, 0, 1);
    float3 objSpaceCameraPos = (node.inverseModelTransform
                                * worldCameraPos).xyz;
    return objSpaceCameraPos - v.xyz;
}

float4 UnityObjectToClipPos(float3 inPos, NodeBuffer node)
{
    float4 clipPos = node.modelViewProjectionTransform * float4(inPos, 1);
    return clipPos;
}

float3 UnityObjectToWorldNormal(float3 norm, NodeBuffer node)
{
    float3 worldNormal = (node.modelTransform * float4(norm, 1)).xyz;
    return normalize(worldNormal);
}

float localToDepth(float3 localPos, NodeBuffer node)
{
    float4 clipPos = UnityObjectToClipPos(localPos, node);
    return clipPos.z / clipPos.w;
}

float3 calculateLighting(float3 col, float3 normal, float3 lightDir, float3 eyeDir, float3 specularIntensity)
{
    float ndotl = max(mix(0, 1.5, dot(normal, lightDir)), 0.5);
    float3 diffuse = ndotl * col;
    float3 v = eyeDir;
    float3 r = normalize(reflect(-lightDir, normal));
    float rdotv = max(dot(r, v), 0.0);
    float3 specular = pow(rdotv, 32) * float3(1) * specularIntensity;
    return diffuse + specular;
}

struct VertexIn {
    float3 position  [[attribute(SCNVertexSemanticPosition)]];
    float3 normal   [[ attribute(SCNVertexSemanticNormal) ]];
    float4 color [[ attribute(SCNVertexSemanticColor) ]];
    float2 uv [[ attribute(SCNVertexSemanticTexcoord0) ]];
};

struct VertexOut {
    float4 position [[position]];
    float3 localPosition;
    float3 normal;
};

struct FragmentOut {
    float4 color [[color(0)]];
    float depth [[depth(any)]];
};

vertex VertexOut vertex_func(
    VertexIn in [[ stage_in ]],
    constant NodeBuffer& scn_node [[ buffer(1) ]]
)
{
    VertexOut out;
    out.position = UnityObjectToClipPos(in.position, scn_node);
    out.normal = UnityObjectToWorldNormal(in.normal, scn_node);
    out.localPosition = in.position;
    return out;
}

FragmentOut maximum_intensity_projection(
    VertexOut in,
    SCNSceneBuffer scn_frame,
    NodeBuffer scn_node,
    int quality,
    texture3d<float, access::sample> volume
)
{
    constexpr sampler sampler(coord::normalized,
                              filter::linear,
                              address::clamp_to_edge);
    FragmentOut out;
    
    const float boxDiagonal = sqrt(3.0);
    const float stepSize = boxDiagonal / quality;

    float3 rayStartPos = in.localPosition + float3(0.5, 0.5, 0.5);
    float3 rayDir = ObjSpaceViewDir(float4(in.localPosition, 1), scn_node, scn_frame);
    rayDir = normalize(rayDir);

    float maxDensity = 0;
    for (int iStep = 0; iStep < quality; iStep++)
    {
        const float t = iStep * stepSize;
        const float3 currPos = rayStartPos + rayDir * t;

        // compare number should have little more bounds, because of cutting issue
        if (currPos.x < -1e-6 || currPos.x >= 1+1e-6 ||
            currPos.y < -1e-6 || currPos.y > 1+1e-6 ||
            currPos.z < -1e-6 || currPos.z > 1+1e-6)
            break;

        float density = volume.sample(sampler, currPos).r;
        if (density > 0.1)
            maxDensity = max(maxDensity, density);
    }
    
    if (maxDensity <  1e-6) discard_fragment();
    
    out.color = float4(maxDensity);
    out.depth = localToDepth(in.localPosition, scn_node);
    return out;
}

FragmentOut surface_rendering(
    VertexOut in,
    SCNSceneBuffer scn_frame,
    NodeBuffer scn_node,
    int quality,
    texture3d<float, access::sample> volume,
    texture3d<float, access::sample> gradient,
    texture2d<float, access::sample> transferColor
)
{
    constexpr sampler sampler(coord::normalized,
                              filter::linear,
                              address::clamp_to_edge);
    FragmentOut out;
    
    const float boxDiagonal = sqrt(3.0);
    const float stepSize = boxDiagonal / quality;

    float3 rayStartPos = in.localPosition + float3(0.5, 0.5, 0.5);
    float3 rayDir = normalize(ObjSpaceViewDir(float4(in.localPosition, 0), scn_node, scn_frame));
    
    // Start from the end, tand trace towards the vertex
    rayStartPos += rayDir * stepSize * quality;
    rayDir = -rayDir;

    // Create a small random offset in order to remove artifacts
    rayStartPos = rayStartPos + (2.0 * rayDir / quality) * scn_frame.random01;

    float4 col = float4(0);
    for (int iStep = 0; iStep < quality; iStep++)
    {
        const float t = iStep * stepSize;
        const float3 currPos = rayStartPos + rayDir * t;

        if (currPos.x < 0 || currPos.x >= 1 ||
            currPos.y < 0 || currPos.y > 1 ||
            currPos.z < 0 || currPos.z > 1)
            continue;

        float density = volume.sample(sampler, currPos).r;
        if (density > 0.1)
        {
            //float3 normal = normalize(gradient.sample(sampler, currPos).rgb);
            col = transferColor.sample(sampler, float2(density, 0));
            //col.rgb = calculateLighting(col.rgb, normal, -rayDir, -rayDir, 0.15);
            col.a = 1;
            break;
        }
    }
    
    if (col.a <  1e-6) discard_fragment();
    
    out.color = col;
    out.depth = localToDepth(in.localPosition, scn_node);
    return out;
}

FragmentOut direct_volume_rendering(
    VertexOut in,
    SCNSceneBuffer scn_frame,
    NodeBuffer scn_node,
    int quality,
    texture3d<float, access::sample> volume,
    texture3d<float, access::sample> gradient,
    texture2d<float, access::sample> transferColor
)
{
    constexpr sampler sampler(coord::normalized,
                              filter::linear,
                              address::clamp_to_edge);
    FragmentOut out;
    
    const float boxDiagonal = sqrt(3.0);
    const float stepSize = boxDiagonal / quality;

    float3 rayStartPos = in.localPosition + float3(0.5, 0.5, 0.5);
    //float3 lightDir = normalize(ObjSpaceViewDir((float4(0)), scn_node, scn_frame));
    float3 rayDir = ObjSpaceViewDir(float4(in.localPosition, 1), scn_node, scn_frame);
    rayDir = normalize(rayDir);
    
    // Create a small random offset in order to remove artifacts
    rayStartPos = rayStartPos + (2 * rayDir / quality) * scn_frame.random01;

    float4 col = float4();
    for (int iStep = 0; iStep < quality; iStep++)
    {
        const float t = iStep * stepSize;
        const float3 currPos = rayStartPos + rayDir * t;

        if (currPos.x < 0 || currPos.x >= 1 ||
            currPos.y < 0 || currPos.y > 1 ||
            currPos.z < 0 || currPos.z > 1)
            break;

        float density = volume.sample(sampler, currPos).r;
        //float3 normal = gradient.sample(sampler, currPos).xyz;
        
        float4 src = transferColor.sample(sampler, float2(density, 0));
        //src.rgb = calculateLighting(src.rgb, normalize(normal), lightDir, rayDir, 0.3); // let it be slowly
        
        if (density < 0.1)
            src.a = 0;
        
        col.rgb = src.a * src.rgb + (1 - src.a) * col.rgb;
        col.a = src.a + (1 - src.a) * col.a;
        
        if (col.a > 1)
            break;
    }
    
    if (col.a <  1e-6) discard_fragment();
    
    out.color = col;
    out.depth = localToDepth(in.localPosition, scn_node);

    return out;
}

fragment FragmentOut fragment_func(
    VertexOut in [[ stage_in ]],
    constant SCNSceneBuffer& scn_frame [[ buffer(0) ]],
    constant NodeBuffer& scn_node [[ buffer(1) ]],
    constant Uniforms& uniforms [[ buffer(4) ]],
    texture3d<float, access::sample> volume [[ texture(0) ]],
    texture3d<float, access::sample> gradient [[ texture(1) ]],
    texture2d<float, access::sample> transferColor [[ texture(2) ]]
)
{
    int quality = uniforms.renderingQuality;
    
    switch (uniforms.method)
    {
        case 0:
            return surface_rendering(in, scn_frame, scn_node, quality, volume, gradient, transferColor);
        case 1:
            return direct_volume_rendering(in, scn_frame, scn_node, quality, volume, gradient, transferColor);
        default:
            return maximum_intensity_projection(in, scn_frame, scn_node, quality, volume);
            
    }
}


