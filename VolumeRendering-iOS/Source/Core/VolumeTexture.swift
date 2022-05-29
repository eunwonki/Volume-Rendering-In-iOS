import CoreGraphics
import Metal
import UIKit
import simd

class VolumeTextureFactory {
    var part: VolumeCubeMaterial.BodyPart
    var resolution: float3
    var dimension: int3
    var scale: float3 {
        return float3(
            resolution.x * Float(dimension.x),
            resolution.y * Float(dimension.y),
            resolution.z * Float(dimension.z)
        )
    }
    
    init(_ part: VolumeCubeMaterial.BodyPart)
    {
        self.part = part
        
        if part == .head {
            resolution = float3(0.000449, 0.000449, 0.000501)
            dimension = int3(512, 512, 511)
            return
        }
        
        else if part == .chest{
            resolution = float3(0.000586, 0.000586, 0.002)
            dimension = int3(512, 512, 179)
            return
        }
        
        resolution = float3(1, 1, 1)
        dimension = int3(1, 1, 1)
    }
    
    func generate(device: MTLDevice) -> MTLTexture
    {
        // example data type specification
        // type: Int16
        // size: dimension.x * dimension.y * dimension.z
        
        let filename = part == .head ? "head" : "chest"
        let url = Bundle.main.url(forResource: filename, withExtension: "raw")!
        let data = try! Data(contentsOf: url)
        
        let descriptor = MTLTextureDescriptor()
        descriptor.textureType = .type3D
        descriptor.pixelFormat = .r16Sint
        descriptor.width = Int(dimension.x)
        descriptor.height = Int(dimension.y)
        descriptor.depth = Int(dimension.z)
        descriptor.usage = .shaderRead
        
        let bytesPerRow = MemoryLayout<Int16>.size * descriptor.width
        let bytesPerImage = bytesPerRow * descriptor.height
        
        let texture = device.makeTexture(descriptor: descriptor)
        texture?.replace(region: MTLRegionMake3D(0, 0, 0,
                                                 descriptor.width,
                                                 descriptor.height,
                                                 descriptor.depth),
                         mipmapLevel: 0,
                         slice: 0,
                         withBytes: (data as NSData).bytes,
                         bytesPerRow: bytesPerRow,
                         bytesPerImage: bytesPerImage)
        
        return texture!
    }
}
