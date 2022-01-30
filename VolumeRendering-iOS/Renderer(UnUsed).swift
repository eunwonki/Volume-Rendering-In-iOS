import MetalKit
import SceneKit

struct Vertex: sizeable {
    var position = float3();
    var normal = float3();
    var color = float4()
    var coordinate = float2()
}

class Renderer: NSObject {
    let device: MTLDevice!
    let commandQueue: MTLCommandQueue!
    let pipelineState: MTLRenderPipelineState!
    let depthState: MTLDepthStencilState!
    
//    var parameter = Parameter()
    
    var vertexBuffer: MTLBuffer?
    var vertexCount = 0
    var indexBuffer: MTLBuffer?
    var indexCount = 0
    
    var texture: MTLTexture?
    static var aspectRatio: Float = 1
    
    init(_ view: MTKView) {
        self.device = view.device!
        self.commandQueue = device.makeCommandQueue()!
        
        let size = view.frame.size
        Renderer.aspectRatio = Float(size.width / size.height)
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.colorAttachments[0].pixelFormat = view.colorPixelFormat
        pipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .oneMinusSourceAlpha
        pipelineDescriptor.depthAttachmentPixelFormat = view.depthStencilPixelFormat
        pipelineDescriptor.vertexDescriptor = Renderer.vertexDescriptor()
        
        let library = device.makeDefaultLibrary()!
        pipelineDescriptor.vertexFunction = library.makeFunction(name: "vertex_func")
        pipelineDescriptor.fragmentFunction = library.makeFunction(name: "fragment_func")
        
        self.pipelineState = try! device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        
        let depthStencilDescriptor = MTLDepthStencilDescriptor()
        depthStencilDescriptor.depthCompareFunction = .lessEqual
        depthStencilDescriptor.isDepthWriteEnabled = true
        
        self.depthState = device.makeDepthStencilState(descriptor: depthStencilDescriptor)
        
        super.init()
        
        setVertexBuffer()
        (texture, _) = VolumeTexture.get(device: device)
    }
    
    static func vertexDescriptor() -> MTLVertexDescriptor {
        let vertexDescriptor = MTLVertexDescriptor()
        
        // position
        vertexDescriptor.attributes[0].format = .float3
        vertexDescriptor.attributes[0].bufferIndex = 0
        vertexDescriptor.attributes[0].offset = 0
        
        // normal
        vertexDescriptor.attributes[1].format = .float3
        vertexDescriptor.attributes[1].bufferIndex = 0
        vertexDescriptor.attributes[1].offset = float3.size
        
        // color
        vertexDescriptor.attributes[2].format = .float4
        vertexDescriptor.attributes[2].bufferIndex = 0
        vertexDescriptor.attributes[2].offset = float3.size + float3.size
        
        // coordinate
        vertexDescriptor.attributes[3].format = .float2
        vertexDescriptor.attributes[3].bufferIndex = 0
        vertexDescriptor.attributes[3].offset = float3.size + float3.size + float4.size
        
        vertexDescriptor.layouts[0].stride = Vertex.stride
        
        return vertexDescriptor
    }
    
    func setVertexBuffer() {
        let vertices = CubeGeometry.VERTEX_ARRAY()
        vertexCount = CubeGeometry.VERTEX_COUNT
        vertexBuffer = device.makeBuffer(bytes: vertices,
                                         length: Vertex.stride(vertices.count),
                                         options: [])!
        
        let indices = CubeGeometry.TRIANGLE.map { Int16($0) }
        indexCount = CubeGeometry.TRIANGLE_COUNT * 3
        indexBuffer = device.makeBuffer(bytes: indices,
                                        length: 2 * indexCount,
                                        options: [])
    }
    
    var isSet = false;
    func updateModelViewMatrix() {
//        let viewPort = CGSize(width: 1194, height: 834)
//        parameter.viewMatrix =
//            float4x4(cameraController?.pointOfView?.transform
//                     ?? SCNMatrix4Identity)
//        parameter.inverseViewMatrix = parameter.viewMatrix.inverse
//        parameter.projectionMatrix =
//            float4x4(cameraController?.pointOfView?.camera?.projectionTransform(withViewportSize: viewPort)
//                    ?? SCNMatrix4Identity)
//        parameter.inverseProjectionMatrix = parameter.projectionMatrix.inverse
//        parameter.cameraWorldPos =
//            float3(cameraController?.pointOfView?.position ??
//            SCNVector3())
//        parameter.quality = 128
    }
}

extension Renderer: MTKViewDelegate {
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
    
    func draw(in view: MTKView) {
        updateModelViewMatrix()
        
        guard let rpd = view.currentRenderPassDescriptor,
              let drawable = view.currentDrawable else { return }
        guard let cb = commandQueue.makeCommandBuffer() else { return }
        cb.label = "Command Buffer"
        
        let rce = cb.makeRenderCommandEncoder(descriptor: rpd)
        rce?.label = "Render Command Encoder 1"
        
        guard let rce = rce,
              let vertexBuffer = vertexBuffer,
              let indexBuffer = indexBuffer else { return }
        rce.setRenderPipelineState(pipelineState)
        rce.setDepthStencilState(depthState)
        rce.setCullMode(.front)
        
//        guard let parameters = device.makeBuffer(bytes: &parameter,
//                                                 length: Parameter.stride,
//                                                 options: [])
//        else {
//            return
//        }

        rce.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
//        rce.setVertexBuffer(parameters, offset: 0, index: 1)
        rce.setFragmentTexture(texture, index: 0)
//        rce.setFragmentBuffer(parameters, offset: 0, index: 1)
        
        rce.drawIndexedPrimitives(type: .triangle,
                                  indexCount: indexCount,
                                  indexType: .uint16,
                                  indexBuffer: indexBuffer,
                                  indexBufferOffset: 0)
        rce.endEncoding()
        
        cb.present(drawable)
        cb.commit()
    }
}
