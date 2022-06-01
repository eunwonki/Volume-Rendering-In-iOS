#include <metal_stdlib>
#include "shared.metal"

using namespace metal;

struct Uniforms {
    bool isLightingOn;
    int method;
    int renderingQuality;
    int voxelMinValue;
    int voxelMaxValue;
};

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
    // TODO: Volume Rendering Depth 구현.
    // Volume Rendering이 Ray 방향의 픽셀들의 종합 연산이라 어떤 Depth를 사용해야 하는지 애매함.
    float4 color [[color(0)]];
    //float depth [[depth(any)]];
};

vertex VertexOut
volume_vertex(VertexIn in [[ stage_in ]],
              constant NodeBuffer& scn_node [[ buffer(1) ]]
              )
{
    VertexOut out;
    out.position = Unity::ObjectToClipPos(in.position, scn_node);
    out.normal = Unity::ObjectToWorldNormal(in.normal, scn_node);
    out.localPosition = in.position;
    return out;
}

FragmentOut
surface_rendering(VertexOut in,
                  SCNSceneBuffer scn_frame,
                  NodeBuffer scn_node,
                  int quality,
                  texture3d<short, access::sample> volume,
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
    float3 rayDir = normalize(Unity::ObjSpaceViewDir(float4(in.localPosition, 0), scn_node, scn_frame));
    
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
    return out;
}

FragmentOut
direct_volume_rendering(VertexOut in,
                        SCNSceneBuffer scn_frame,
                        NodeBuffer scn_node,
                        int quality, int minValue, int maxValue,
                        bool isLightingOn,
                        texture3d<short, access::sample> dicom,
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
    float3 lightDir = normalize(Unity::ObjSpaceViewDir((float4(0)), scn_node, scn_frame));
    float3 rayDir = Unity::ObjSpaceViewDir(float4(in.localPosition, 1), scn_node, scn_frame);
    rayDir = normalize(rayDir);
    
    // Create a small random offset in order to remove artifacts
    rayStartPos = rayStartPos + (2 * rayDir / quality);
    
    float4 col = float4();
    for (int iStep = 0; iStep < quality; iStep++)
    {
        const float t = iStep * stepSize;
        const float3 currPos = rayStartPos + rayDir * t;
        
        if (currPos.x < 0 || currPos.x >= 1 ||
            currPos.y < 0 || currPos.y > 1 ||
            currPos.z < 0 || currPos.z > 1)
            break;
        
        short hu = dicom.sample(sampler, currPos).r;
        float density = Util::normalize(hu, minValue, maxValue);
        
        float4 src = transferColor.sample(sampler, float2(density, 0));
        if (isLightingOn) {
            float3 gradient = Util::calGradient(dicom, sampler, currPos);
            float3 normal = normalize(gradient);
            src.rgb = Util::calculateLighting(src.rgb, normal, lightDir, rayDir, 0.3);
        }
        
        if (density < 0.1)
            src.a = 0;
        
        col.rgb = src.a * src.rgb + (1 - src.a) * col.rgb;
        col.a = src.a + (1 - src.a) * col.a;
        
        if (col.a > 1)
            break;
    }
    
    out.color = col;
    
    return out;
}

fragment FragmentOut
volume_fragment(VertexOut in [[ stage_in ]],
                constant SCNSceneBuffer& scn_frame [[ buffer(0) ]],
                constant NodeBuffer& scn_node [[ buffer(1) ]],
                constant Uniforms& uniforms [[ buffer(4) ]],
                texture3d<short, access::sample> dicom [[ texture(0) ]],
                texture3d<float, access::sample> gradient [[ texture(2) ]],
                texture2d<float, access::sample> transferColor [[ texture(3) ]]
                )
{
    int quality = uniforms.renderingQuality;
    int minValue = uniforms.voxelMinValue;
    int maxValue = uniforms.voxelMaxValue;
    bool isLightingOn = uniforms.isLightingOn;
    
    switch (uniforms.method)
    {
        case 0:
            return surface_rendering(in, scn_frame, scn_node,
                                     quality,
                                     dicom, transferColor);
        default:
            return direct_volume_rendering(in, scn_frame, scn_node,
                                           quality, minValue, maxValue, isLightingOn,
                                           dicom, transferColor);
    }
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
    float3 rayDir = Unity::ObjSpaceViewDir(float4(in.localPosition, 1), scn_node, scn_frame);
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
    return out;
}
