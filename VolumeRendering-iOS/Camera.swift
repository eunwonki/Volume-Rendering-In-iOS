import simd

class Camera {
    var position = float3(0, 0, -3)
    
    var transform: float4x4 {
        matrix_identity_float4x4
            .translateMatrix(direction: position)
    }

    var projection =
        simd_float4x4.perspective(degreesFov: 45.0,
                                  aspectRatio: Renderer.aspectRatio,
                                  near: 0.1,
                                  far: 10)
}
