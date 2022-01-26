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

// https://github.com/TwoTailsGames/Unity-Built-in-Shaders
float3 ObjSpaceViewDir(float4 v, NodeBuffer node, SCNSceneBuffer scene)
{
    float4 worldCameraPos = scene.viewTransform.columns[3];
    float3 objSpaceCameraPos = (scene.inverseViewProjectionTransform
                                * worldCameraPos).xyz;
    return objSpaceCameraPos - v.xyz;
}

float4 UnityObjectToClipPos(float3 inPos, NodeBuffer node, SCNSceneBuffer scene)
{
    float3 worldPos = (node.modelTransform * float4(inPos, 1)).xyz;
    float4 clipPos = scene.viewProjectionTransform * float4(worldPos, 1);
    return clipPos;
}

float3 UnityObjectToWorldNormal(float3 norm, NodeBuffer node)
{
    float3 worldNormal = (node.modelTransform * float4(norm, 1)).xyz;
    return normalize(worldNormal);
}

float localToDepth(float3 localPos, NodeBuffer node, SCNSceneBuffer scene)
{
    float4 clipPos = UnityObjectToClipPos(localPos, node, scene);
    return clipPos.z / clipPos.w;
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
    constant SCNSceneBuffer& scn_frame [[ buffer(0) ]],
    constant NodeBuffer& scn_node [[ buffer(1) ]])
{
    VertexOut out;
    out.position = UnityObjectToClipPos(in.position, scn_node, scn_frame);
    out.normal = UnityObjectToWorldNormal(in.normal, scn_node);
    out.localPosition = in.position;
    return out;
}

fragment FragmentOut fragment_func(
    VertexOut in [[ stage_in ]],
    constant SCNSceneBuffer& scn_frame [[ buffer(0) ]],
    constant NodeBuffer& scn_node [[ buffer(1) ]],
    constant int& quality [[ buffer(2) ]],
    texture3d<float, access::sample> volume [[ texture(0) ]]
//    texture3d<float, access::sample> gradient [[ texture(1) ]],
//    texture2d<float, access::sample> transferColor [[ texture(2) ]],
//    texture2d<float, access::sample> noise [[texture(3)]]
)
{
    constexpr sampler sampler(coord::normalized,
                              filter::linear,
                              address::clamp_to_edge);
    FragmentOut out;
    
    const float boxDiagonal = 1.732;
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
        if (currPos.x < -1e-6 || currPos.x > 1+1e-6 ||
            currPos.y < -1e-6 || currPos.y > 1+1e-6 ||
            currPos.z < -1e-6 || currPos.z > 1+1e-6)
            break;

        float density = volume.sample(sampler, currPos).r;
        if (density > 0.1)
            maxDensity = max(maxDensity, density);
    }
    
    if (maxDensity <  0.0001) discard_fragment();
    
    out.color = float4(maxDensity);
    out.depth = localToDepth(in.localPosition, scn_node, scn_frame);
    return out;
}


