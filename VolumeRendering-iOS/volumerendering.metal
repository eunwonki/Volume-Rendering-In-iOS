#include <metal_stdlib>
using namespace metal;

// data 3d texture
// gradient 3d texture
// noise 2d texture
// tf 2d texture
// quality int

struct VertexIn {
    float3 position [[ attribute(0) ]];
    float3 normal [[ attribute(1) ]];
    float2 texcoord [[ attribute(2) ]];
};

struct VertexOut {
    float4 position [[position]];
    float2 texcoord;
    float3 vertexLocal;
    float3 normal;
};

struct FragmentOut {
    float4 color [[color(0)]];
    float depth [[depth(any)]];
};

vertex VertexOut vertex_func(VertexIn in [[stage_in]])
{
    VertexOut out;
    out.position = float4(in.position, 1);
    // out.position = (mvp * float4(in.position, 1)).xyz;
    out.texcoord = in.texcoord;
    // out.normal = in.normal // converto world normal
    return out;
}

fragment FragmentOut fragment_func()
{
    FragmentOut out;
    out.color =  float4(1, 0, 0, 1);
    out.depth = 1.0;
    return out;
}


