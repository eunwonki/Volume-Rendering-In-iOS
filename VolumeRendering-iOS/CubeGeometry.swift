import Foundation
import SwiftUI
import SceneKit

class CubeGeometry {
    static let VERTEX_COUNT = 24
    static let VERTEX = [
        float3(0.5, -0.5, 0.5),
        float3(-0.5, -0.5, 0.5),
        float3(0.5, 0.5, 0.5),
        float3(-0.5, 0.5, 0.5),
        float3(0.5, 0.5, -0.5),
        float3(-0.5, 0.5, -0.5),
        float3(0.5, -0.5, -0.5),
        float3(-0.5, -0.5, -0.5),
        float3(0.5, 0.5, 0.5),
        float3(-0.5, 0.5, 0.5),
        float3(0.5, 0.5, -0.5),
        float3(-0.5, 0.5, -0.5),
        float3(0.5, -0.5, -0.5),
        float3(0.5, -0.5, 0.5),
        float3(-0.5, -0.5, 0.5),
        float3(-0.5, -0.5, -0.5),
        float3(-0.5, -0.5, 0.5),
        float3(-0.5, 0.5, 0.5),
        float3(-0.5, 0.5, -0.5),
        float3(-0.5, -0.5, -0.5),
        float3(0.5, -0.5, -0.5),
        float3(0.5, 0.5, -0.5),
        float3(0.5, 0.5, 0.5),
        float3(0.5, -0.5, 0.5),
    ]
    static let NORMAL = [
        float3(0.0, 0.0, 1.0),
        float3(0.0, 0.0, 1.0),
        float3(0.0, 0.0, 1.0),
        float3(0.0, 0.0, 1.0),
        float3(0.0, 1.0, 0.0),
        float3(0.0, 1.0, 0.0),
        float3(0.0, 0.0, -1.0),
        float3(0.0, 0.0, -1.0),
        float3(0.0, 1.0, 0.0),
        float3(0.0, 1.0, 0.0),
        float3(0.0, 0.0, -1.0),
        float3(0.0, 0.0, -1.0),
        float3(0.0, -1.0, 0.0),
        float3(0.0, -1.0, 0.0),
        float3(0.0, -1.0, 0.0),
        float3(0.0, -1.0, 0.0),
        float3(-1.0, 0.0, 0.0),
        float3(-1.0, 0.0, 0.0),
        float3(-1.0, 0.0, 0.0),
        float3(-1.0, 0.0, 0.0),
        float3(1.0, 0.0, 0.0),
        float3(1.0, 0.0, 0.0),
        float3(1.0, 0.0, 0.0),
        float3(1.0, 0.0, 0.0),
    ]
    static let TEXCOORD = [
        float2(0.0, 0.0),
        float2(1.0, 0.0),
        float2(0.0, 1.0),
        float2(1.0, 1.0),
        float2(0.0, 1.0),
        float2(1.0, 1.0),
        float2(0.0, 1.0),
        float2(1.0, 1.0),
        float2(0.0, 0.0),
        float2(1.0, 0.0),
        float2(0.0, 0.0),
        float2(1.0, 0.0),
        float2(0.0, 0.0),
        float2(0.0, 1.0),
        float2(1.0, 1.0),
        float2(1.0, 0.0),
        float2(0.0, 0.0),
        float2(0.0, 1.0),
        float2(1.0, 1.0),
        float2(1.0, 0.0),
        float2(0.0, 0.0),
        float2(0.0, 1.0),
        float2(1.0, 1.0),
        float2(1.0, 0.0),
    ]
    static let COLOR = [
        float4(1, 0, 1, 1),
        float4(0, 0, 1, 1),
        float4(1, 1, 1, 1),
        float4(0, 1, 1, 1),
        float4(1, 1, 0, 1),
        float4(0, 1, 0, 1),
        float4(1, 0, 0, 1),
        float4(0, 0, 0, 1),
        float4(1, 1, 1, 1),
        float4(0, 1, 1, 1),
        float4(1, 1, 0, 1),
        float4(0, 1, 0, 1),
        float4(1, 0, 0, 1),
        float4(1, 0, 1, 1),
        float4(0, 0, 1, 1),
        float4(0, 0, 0, 1),
        float4(0, 0, 1, 1),
        float4(0, 1, 1, 1),
        float4(0, 1, 0, 1),
        float4(0, 0, 0, 1),
        float4(1, 0, 0, 1),
        float4(1, 1, 0, 1),
        float4(1, 1, 1, 1),
        float4(1, 0, 1, 1)
    ]
    static let TRIANGLE_COUNT = 12
    static let TRIANGLE = [
        0, 2, 3,
        0, 3, 1,
        8, 4, 5,
        8, 5, 9,
        10, 6, 7,
        10, 7, 11,
        12, 13, 14,
        12, 14, 15,
        16, 17, 18,
        16, 18, 19,
        20, 21, 22,
        20, 22, 23,
    ]

    static func VERTEX_ARRAY() -> [Vertex] {
        var vertices: [Vertex] = []
        for i in 0 ..< VERTEX_COUNT {
            vertices.append(Vertex(position: VERTEX[i],
                                   normal: NORMAL[i],
                                   color: COLOR[i],
                                   coordinate: TEXCOORD[i]))
        }
        return vertices
    }
}

class VolumeCube: SCNGeometry {
    var texture: MTLTexture?
    
    init(view: SCNView)
    {
        super.init()
        
        let program = SCNProgram()
        program.vertexFunctionName = "vertex_func"
        program.fragmentFunctionName = "fragment_func"
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
