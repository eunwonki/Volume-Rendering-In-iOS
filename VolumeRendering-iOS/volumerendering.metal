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
    out.position = float4(in.position, 1);
    // out.position = (mvp * float4(in.position, 1)).xyz;
    out.texcoord = in.texcoord;
    // out.normal = in.normal // converto world normal
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
    FragmentOut out;
    out.color =  in.color;
    out.depth = 1.0;
    return out;
}


