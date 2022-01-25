import MetalKit

class Renderer: NSObject {
    let device: MTLDevice!
    let commandQueue: MTLCommandQueue!
    let pipelineState: MTLRenderPipelineState!
    let depthState: MTLDepthStencilState!
    
    var parameter = Parameter()
    var camera = Camera()
    
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
        setTexture()
        
        parameter.viewMatrix = camera.transform
        parameter.inverseViewMatrix = parameter.viewMatrix.inverse
        parameter.projectionMatrix = camera.projection
        parameter.inverseProjectionMatrix = camera.projection.inverse
        parameter.cameraWorldPos = camera.position
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
    
    func setTexture() {
        let width = 512
        let height = 512
        let depth = 161
        let channel = 1
        
        let values = UnsafeMutablePointer<Float>
            .allocate(capacity: width * height * depth * channel)
        
        for i in 0 ..< depth {
            let ptr = values.advanced(by: width * height * channel * i)
            let name = String(format: "%04d", arguments: [i])
            let path = Bundle.main.path(forResource: name, ofType: "png")!
            let image = UIImage(contentsOfFile: path)!.cgImage!
            let bitmapInfo =
                CGImageAlphaInfo.none.rawValue
                    | CGBitmapInfo.byteOrder32Little.rawValue
                    | CGBitmapInfo.floatComponents.rawValue
            let colorSpace = CGColorSpaceCreateDeviceGray()
            let context =
                CGContext(data: ptr,
                          width: width,
                          height: height,
                          bitsPerComponent: 32,
                          bytesPerRow: width * 4,
                          space: colorSpace,
                          bitmapInfo: bitmapInfo)!
            
            context.draw(image, in: CGRect(x: 0, y: 0,
                                           width: width, height: height))
        }
        
        let textureDescriptor = MTLTextureDescriptor()
        textureDescriptor.textureType = .type3D
        textureDescriptor.pixelFormat = .r32Float
        textureDescriptor.width = width
        textureDescriptor.height = height
        textureDescriptor.depth = depth
        textureDescriptor.usage = .shaderRead
        
        texture = device.makeTexture(descriptor: textureDescriptor)!
        texture!.replace(region: MTLRegionMake3D(0, 0, 0,
                                                 width, height, depth),
                         mipmapLevel: 0,
                         slice: 0,
                         withBytes: values,
                         bytesPerRow: Float.size * channel * width,
                         bytesPerImage: width * height * Float.size * channel)
        
         values.deallocate()
    }
    
    func updateModelViewMatrix() {
        if Gesture.isDragging {
            let diff = Gesture.currentDragDiff
            let delta: Float = 0.0001
            
            parameter.modelMatrix.rotate(angle: Float(diff.height) * delta,
                                         axis: X_AXIS)
            parameter.modelMatrix.rotate(angle: Float(diff.width) * delta,
                                         axis: Y_AXIS)
            parameter.viewMatrix = camera.transform
            parameter.projectionMatrix = camera.projection
            
            parameter.inverseModelMatrix = parameter.modelMatrix.inverse
            parameter.inverseViewMatrix = parameter.viewMatrix.inverse
            parameter.inverseProjectionMatrix = parameter.projectionMatrix.inverse
            parameter.cameraWorldPos = camera.position
            
            parameter.quality = 128
        }
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
        
        guard let parameters = device.makeBuffer(bytes: &parameter,
                                                 length: Parameter.stride,
                                                 options: [])
        else {
            return
        }

        rce.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        rce.setVertexBuffer(parameters, offset: 0, index: 1)
        rce.setFragmentTexture(texture, index: 0)
        rce.setFragmentBuffer(parameters, offset: 0, index: 1)
        
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
