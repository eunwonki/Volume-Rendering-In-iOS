import MetalKit

class Renderer: NSObject {
    let device: MTLDevice!
    let commandQueue: MTLCommandQueue!
    let pipelineState: MTLRenderPipelineState!
    
    var vertexBuffer: MTLBuffer?
    var vertexCount = 0
    var indexBuffer: MTLBuffer?
    var indexCount = 0
    
    init(_ view: MTKView) {
        self.device = view.device!
        self.commandQueue = device.makeCommandQueue()!
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.colorAttachments[0].pixelFormat = view.colorPixelFormat
        pipelineDescriptor.depthAttachmentPixelFormat = view.depthStencilPixelFormat
        pipelineDescriptor.vertexDescriptor = Renderer.vertexDescriptor()
        
        let library = device.makeDefaultLibrary()!
        pipelineDescriptor.vertexFunction = library.makeFunction(name: "vertex_func")
        pipelineDescriptor.fragmentFunction = library.makeFunction(name: "fragment_func")
        
        self.pipelineState = try! device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        
        super.init()
        
        setVertexBuffer()
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
}

extension Renderer: MTKViewDelegate {
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
    
    func draw(in view: MTKView) {
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

        rce.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
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
