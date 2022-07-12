// from: https://github.com/mlavik1/UnityVolumeRendering/blob/master/Assets/Shaders/DirectVolumeRenderingShader.shader

#include <metal_stdlib>
#include "shared.metal"

using namespace metal;

struct Uniforms {
    bool isLightingOn;
    bool isBackwardOn;
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
    float2 uv;
};

struct FragmentOut {
    // TODO: Volume Rendering Depth 구현.
    // Volume Rendering이 Ray 방향의 픽셀들의 종합 연산이라 어떤 Depth를 사용해야 하는지 애매함.
    float4 color [[color(0)]];
    //float depth [[depth(any)]];
};

vertex VertexOut
volume_vertex(
  VertexIn in [[ stage_in ]],
  constant NodeBuffer& scn_node [[ buffer(1) ]]
)
{
    VertexOut out;
    out.position = Unity::ObjectToClipPos(float4(in.position, 1.0f), scn_node);
    out.uv = in.uv;
    out.normal = Unity::ObjectToWorldNormal(in.normal, scn_node);
    out.localPosition = in.position;
    return out;
}

FragmentOut
surface_rendering(VertexOut in,
  SCNSceneBuffer scn_frame,
  NodeBuffer scn_node,
  int quality, short minV, short maxV,
  texture3d<short, access::sample> volume,
  texture2d<float, access::sample> transferColor
)
{
    FragmentOut out;
    
    VR::RayInfo ray = VR::getRayFront2Back(in.localPosition, scn_node, scn_frame);
    VR::RaymarchInfo raymarch = VR::initRayMarch(ray, quality);
    float3 lightDir = normalize(Unity::ObjSpaceViewDir(float4(0.0f), scn_node, scn_frame));
    
    // Create a small random offset in order to remove artifacts
    ray.startPosition = ray.startPosition + (2.0 * ray.direction / raymarch.numSteps);
    
    float4 col = float4(0);
    for (int iStep = 0; iStep < raymarch.numSteps; iStep++)
    {
        const float t = iStep * raymarch.numStepsRecip;
        const float3 currPos = Util::lerp(ray.startPosition, ray.endPosition, t);
        

        if (currPos.x < 0 || currPos.x >= 1 ||
            currPos.y < 0 || currPos.y > 1 ||
            currPos.z < 0 || currPos.z > 1)
            continue;
        short hu = VR::getDensity(volume, currPos);
        float density = Util::normalize(hu, minV, maxV);
        if (density > 0.2)
        {
            float3 graident = VR::calGradient(volume, currPos);
            float3 normal = normalize(graident);
            col = VR::getTfColour(transferColor, density);
            col.rgb = Util::calculateLighting(col.rgb, normal, lightDir, ray.direction, 0.15f);
            col.a = 1;
            break;
        }
    }
    
    out.color = col;
    return out;
}

FragmentOut
direct_volume_rendering(
  VertexOut in,
  SCNSceneBuffer scn_frame,
  NodeBuffer scn_node,
  int quality, int minValue, int maxValue,
  bool isLightingOn, bool isBackwardOn,
  texture3d<short, access::sample> dicom,
  texture2d<float, access::sample> tfTable
)
{
    FragmentOut out;
    
    VR::RayInfo ray;
    if (isBackwardOn)
        ray = VR::getRayBack2Front(in.localPosition,
                                   scn_node, scn_frame);
    else
        ray = VR::getRayFront2Back(in.localPosition,
                                   scn_node, scn_frame);
    
    VR::RaymarchInfo raymarch = VR::initRayMarch(ray, quality);
    float3 lightDir = normalize(Unity::ObjSpaceViewDir(float4(0.0f), scn_node, scn_frame));
    
    // Create a small random offset in order to remove artifacts
    ray.startPosition = ray.startPosition + (2 * ray.direction / raymarch.numSteps);
    
    //float tDepth = 0.0f;
    //tDepth = raymarch.numStepRecip * (raymarch.numSteps - 1); // backward off
    
    float4 col = float4(0.0f);
    for (int iStep = 0; iStep < raymarch.numSteps; iStep++)
    {
        const float t = iStep * raymarch.numStepsRecip;
        const float3 currPos = Util::lerp(ray.startPosition, ray.endPosition, t);
        
        if (currPos.x < 0 || currPos.x >= 1 ||
            currPos.y < 0 || currPos.y > 1 ||
            currPos.z < 0 || currPos.z > 1)
            break;
        
        short hu = VR::getDensity(dicom, currPos);
        float density = Util::normalize(hu, minValue, maxValue);
        
        float4 src = VR::getTfColour(tfTable, density);
        float3 gradient = VR::calGradient(dicom, currPos);
        float3 normal = normalize(gradient);
        float3 direction = isBackwardOn ? ray.direction : -ray.direction;
        
        if (isLightingOn) {
            src.rgb = Util::calculateLighting(src.rgb, normal, lightDir, direction, 0.3f);
        }
        
        if (density < 0.1f)
            src.a = 0.0f;
        
        if (isBackwardOn)
        {
            col.rgb = src.a * src.rgb + (1.0f - src.a) * col.rgb;
            col.a = src.a + (1.0f - src.a) * col.a;
        }
        else
        {
            src.rgb *= src.a;
            col = (1.0f - col.a) * src + col;
        }
        
        if (col.a > 1)
            break;
    }
    
    out.color = col;
    
    return out;
}

FragmentOut maximum_intensity_projection(
    VertexOut in,
    SCNSceneBuffer scn_frame,
    NodeBuffer scn_node,
    int quality, short minV, short maxV,
    texture3d<short, access::sample> volume
)
{
    FragmentOut out;
    
    VR::RayInfo ray = VR::getRayBack2Front(in.localPosition,
                                       scn_node, scn_frame);
    VR::RaymarchInfo raymarchInfo = VR::initRayMarch(ray, quality);
    
    float maxDensity = 0;
    //float3 maxDensityPos = ray.startPosition; // to depth
    for (int iStep = 0; iStep < raymarchInfo.numSteps; iStep++)
    {
        const float t = iStep * raymarchInfo.numStepsRecip;
        const float3 currPos = Util::lerp(ray.startPosition, ray.endPosition, t);

        // compare number should have little more bounds, because of cutting issue
        if (currPos.x < -1e-6 || currPos.x >= 1+1e-6 ||
            currPos.y < -1e-6 || currPos.y > 1+1e-6 ||
            currPos.z < -1e-6 || currPos.z > 1+1e-6)
            break;

        short hu = VR::getDensity(volume, currPos);
        float density = Util::normalize(hu, minV, maxV);
        
        if (density > 0.1f)
            maxDensity = max(maxDensity, density);
    }
    
    out.color = float4(maxDensity);
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
    bool isBackwardOn = uniforms.isBackwardOn;
    
    switch (uniforms.method)
    {
        case 0:
            return surface_rendering(in, scn_frame, scn_node,
                                     quality, minValue, maxValue,
                                     dicom, transferColor);
        case 1:
            return direct_volume_rendering(in, scn_frame, scn_node,
                                           quality, minValue,maxValue,
                                           isLightingOn,isBackwardOn,
                                           dicom, transferColor);
        default:
            return maximum_intensity_projection(in, scn_frame, scn_node, quality, minValue, maxValue, dicom);
    }
}
