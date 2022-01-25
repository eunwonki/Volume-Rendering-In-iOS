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
    float4x4 viewMatrix;
    float4x4 projectionMatrix;
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

vertex VertexOut vertex_func(
    VertexIn in [[ stage_in ]],
    constant Parameter& param [[ buffer(1) ]])
{
    VertexOut out;
    float4x4 mvpMatrix = param.projectionMatrix
    * param.viewMatrix
    * param.modelMatrix;
    out.position = mvpMatrix * float4(in.position, 1);
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
    float3 rayDir = float3(0, 0, 0);

    float maxDensity = 0;
    for (int iStep = 0; iStep < param.quality; iStep++)
    {
        const float t = iStep * stepSize;
        const float3 currPos = rayStartPos + rayDir * t;

//        if (currPos.x < 0.0f || currPos.x > 1.0f ||
//            currPos.y < 0.0f || currPos.y > 1.0f ||
//            currPos.z < 0.0f || currPos.z > 1.0f)
//            break;

        float density = volume.sample(sampler, currPos).r;
        if (density > 0.2)
            maxDensity = max(maxDensity, density);
    }
    
    out.color = float4(maxDensity);
    //out.depth = in.vertexLocal; local to depth
    return out;
}


