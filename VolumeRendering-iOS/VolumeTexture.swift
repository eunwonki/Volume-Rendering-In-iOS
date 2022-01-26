import CoreGraphics
import UIKit
import Metal

class VolumeTexture {
    static func get(device: MTLDevice) -> MTLTexture? {
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
        
        let texture = device.makeTexture(descriptor: textureDescriptor)
        texture?.replace(region: MTLRegionMake3D(0, 0, 0,
                                                 width, height, depth),
                         mipmapLevel: 0,
                         slice: 0,
                         withBytes: values,
                         bytesPerRow: Float.size * channel * width,
                         bytesPerImage: width * height * Float.size * channel)
        
        values.deallocate()
        
        return texture
    }
}
