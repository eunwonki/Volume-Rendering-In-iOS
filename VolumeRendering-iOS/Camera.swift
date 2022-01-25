import simd

class Camera {
    var transform = matrix_identity_float4x4
        .translateMatrix(direction: float3(0, 0, -2))
    var projection =
        simd_float4x4.perspective(degreesFov: 45.0,
                                  aspectRatio: Renderer.aspectRatio,
                                  near: 0.1,
                                  far: 10)
}
