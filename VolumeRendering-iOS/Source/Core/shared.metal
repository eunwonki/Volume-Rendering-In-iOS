#ifndef SHARED_METAL
#define SHARED_METAL

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

class Unity {
public:
    // https://github.com/TwoTailsGames/Unity-Built-in-Shaders
    static float3 ObjSpaceViewDir(float4 v, NodeBuffer node, SCNSceneBuffer scene)
    {
        float4 worldCameraPos = scene.inverseViewTransform * float4(0, 0, 0, 1);
        float3 objSpaceCameraPos = (node.inverseModelTransform
                                    * worldCameraPos).xyz;
        return objSpaceCameraPos - v.xyz;
    }
    
    static float4 ObjectToClipPos(float3 inPos, NodeBuffer node)
    {
        float4 clipPos = node.modelViewProjectionTransform * float4(inPos, 1);
        return clipPos;
    }
    
    static float3 ObjectToWorldNormal(float3 norm, NodeBuffer node)
    {
        float3 worldNormal = (node.modelTransform * float4(norm, 1)).xyz;
        return normalize(worldNormal);
    }
    
    static float Get2DClipping(float2 position, float4 clipRect)
    {
        float2 inside = step(clipRect.xy, position.xy) * step(position.xy, clipRect.zw);
        return inside.x * inside.y;
    }
};

class Util {
public:
    static float normalize(short value, short minValue, short maxValue)
    {
        return float(value - minValue) / float(maxValue - minValue);
    }
    
    static float lerp(float a, float b, float w) {
      return a + w*(b-a);
    }
    
    static float3 calGradient(texture3d<short, access::sample> volume,
                              sampler loader,
                              float3 coord)
    {
        float3 dimension = float3(512, 512, 511); // TODO: Parameter로 받도록
        if(dimension.x < 1.0 || dimension.y < 1.0 || dimension.z < 1.0)
        { return float3(0); }
        
        float x1 = volume.sample(loader, float3(min(coord.x + 1.0 / dimension.x, 1.0),
                                                coord.y,
                                                coord.z)).r;
        float x2 = volume.sample(loader, float3(max(coord.x - 1.0 / dimension.x, 0.0),
                                                coord.y,
                                                coord.z)).r;
        float y1 = volume.sample(loader, float3(coord.x,
                                                min(coord.y + 1.0 / dimension.y, 1.0),
                                                coord.z)).r;
        float y2 = volume.sample(loader, float3(coord.x,
                                                max(coord.y - 1.0 / dimension.y, 0.0),
                                                coord.z)).r;
        float z1 = volume.sample(loader, float3(coord.x,
                                                coord.y,
                                                min(coord.z + 1.0 / dimension.z, 1.0))).r;
        float z2 = volume.sample(loader, float3(coord.x,
                                                coord.y,
                                                max(coord.z - 1.0 / dimension.z, 0.0))).r;
                                 
        return float3(x2 - x1, y2 - y1, z2 - z1);
    }
    
    static float3 calculateLighting(float3 col, float3 normal, float3 lightDir, float3 eyeDir,
                             float specularIntensity)
    {
        float ndotl = max(lerp(0.0, 1.5, dot(normal, lightDir)), 0.5);
        float3 diffuse = ndotl * col;
        float3 v = eyeDir;
        float3 r = ::normalize(reflect(-lightDir, normal));
        float rdotv = max(dot(r, v), 0.0);
        float3 specular = pow(rdotv, 32) * float3(1) * specularIntensity;
        return diffuse + specular;
    }
};

#endif
