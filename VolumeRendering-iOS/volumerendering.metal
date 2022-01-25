#include <metal_stdlib>
using namespace metal;

struct VertexIn {
    float3 position [[ attribute(0) ]];
    float3 normal [[ attribute(1) ]];
    float4 color [[ attribute(2) ]];
    float2 texcoord [[ attribute(3) ]];
};

struct Parameter {
    float4x4 modelMatrix;
    float4x4 inverseModelMatrix;
    float4x4 viewMatrix;
    float4x4 inverseViewMatrix;
    float4x4 projectionMatrix;
    float4x4 inverseProjectionMatrix;
    float3 cameraWorldPos;
    int quality;
};

struct VertexOut {
    float4 position [[position]];
    float2 texcoord;
    float3 vertexLocal;
    float3 normal;
    float4 color;
};

struct FragmentOut {
    float4 color [[color(0)]];
    float depth [[depth(any)]];
};

// https://github.com/TwoTailsGames/Unity-Built-in-Shaders
float3 ObjSpaceViewDir(float4 v, Parameter param)
{
    float3 worldCameraPos = param.cameraWorldPos;
    float3 objSpaceCameraPos = (param.modelMatrix
                                * float4(worldCameraPos, 1)).xyz;
    return objSpaceCameraPos - v.xyz;
}

float4 UnityObjectToClipPos(float3 inPos, Parameter param)
{
    float4 clipPos;
    float3 posWorld = (param.inverseModelMatrix * float4(inPos, 1)).xyz;
    float4x4 viewProjection = param.projectionMatrix * param.viewMatrix;
    clipPos = viewProjection * float4(posWorld, 1);
    return clipPos;
}

float3 UnityObjectToWorldNormal(float3 norm, Parameter param)
{
    float3 worldNormal = (param.inverseModelMatrix * float4(norm, 1)).xyz;
    return normalize(worldNormal);
}

float localToDepth(float3 localPos, Parameter param)
{
    float4 clipPos = UnityObjectToClipPos(localPos, param);
    return clipPos.z / clipPos.w;
}

vertex VertexOut vertex_func(
    VertexIn in [[ stage_in ]],
    constant Parameter& param [[ buffer(1) ]])
{
    VertexOut out;
    out.position = UnityObjectToClipPos(in.position, param);
    out.normal = UnityObjectToWorldNormal(in.normal, param);
    out.vertexLocal = in.position;
    out.texcoord = in.texcoord;
    out.color = in.color;
    return out;
}

fragment FragmentOut fragment_func(
    VertexOut in [[ stage_in ]],
    constant Parameter& param [[ buffer(1) ]],
    texture3d<float, access::sample> volume [[ texture(0) ]],
    texture3d<float, access::sample> gradient [[ texture(1) ]],
    texture2d<float, access::sample> transferColor [[ texture(2) ]],
    texture2d<float, access::sample> noise [[texture(3)]]
)
{
    constexpr sampler sampler(coord::normalized,
                              filter::linear,
                              address::clamp_to_edge);
    FragmentOut out;
    
    const float boxDiagonal = 1.732;
    const float stepSize = boxDiagonal / param.quality;

    float3 rayStartPos = in.vertexLocal + float3(0.5, 0.5, 0.5);
    float3 rayDir = ObjSpaceViewDir(float4(in.vertexLocal, 0), param);
    rayDir = normalize(rayDir);

    float maxDensity = 0;
    for (int iStep = 0; iStep < param.quality; iStep++)
    {
        const float t = iStep * stepSize;
        const float3 currPos = rayStartPos + rayDir * t;

        if (currPos.x < 0.0f || currPos.x > 1.0f ||
            currPos.y < 0.0f || currPos.y > 1.0f ||
            currPos.z < 0.0f || currPos.z > 1.0f)
            break;

        float density = volume.sample(sampler, currPos).r;
        if (density > 0.1)
            maxDensity = max(maxDensity, density);
    }
    
    if (maxDensity ==  0) discard_fragment();
    
    out.color = float4(maxDensity);
    out.depth = localToDepth(in.vertexLocal, param);
    return out;
}


