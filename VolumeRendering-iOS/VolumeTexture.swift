import CoreGraphics
import Metal
import UIKit

class VolumeTexture {
    static func getChest(device: MTLDevice)
        -> MTLTexture
    {
        let width = 512
        let height = 512
        let depth = 161
        let channel = 1
        
        let values = UnsafeMutablePointer<Float>
            .allocate(capacity: width * height * depth * channel)
        
        for i in 0 ..< depth {
            let ptr = values.advanced(by: width * height * channel * i)
            let name = String(format: "Chest%04d", arguments: [i])
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
        
        return texture!
        
        // don't use gradient yet
        
//        channel = 4
//        let gradientData = UnsafeMutablePointer<Float>
//            .allocate(capacity: width * height * depth * channel)
//
//        for i in (width * height) ..< ((width * height * depth) - (width * height)) {
//            if (i + 1) % width == 0 || i % width == 0 { continue }
//            if (i % (width * height)) >= width * (height - 1)
//                || (i % (width * height) < width) { continue }
//            if (i + 1) > width * height * (depth - 1) || i < width * height { continue }
//
//            let xUpper = values[i + 1]
//            let xLower = values[i - 1]
//            let yUpper = values[i + width]
//            let yLower = values[i - width]
//            let zUpper = values[i + (width * height)]
//            let zLower = values[i - (width * height)]
//
//            let gx = (xLower - xUpper)
//            let gy = (yLower - yUpper)
//            let gz = (zLower - zUpper)
//
//            gradientData[i * channel] = gx
//            gradientData[i * channel + 1] = gy
//            gradientData[i * channel + 2] = gz
//            gradientData[i * channel + 3] = values[i]
//        }
//
//        let gradientTextureDescriptor = MTLTextureDescriptor()
//        gradientTextureDescriptor.textureType = .type3D
//        gradientTextureDescriptor.pixelFormat = .rgba32Float
//        gradientTextureDescriptor.width = width
//        gradientTextureDescriptor.height = height
//        gradientTextureDescriptor.depth = depth
//        gradientTextureDescriptor.usage = .shaderRead
//
//        let gradient = device.makeTexture(descriptor: textureDescriptor)
//        gradient?.replace(region: MTLRegionMake3D(0, 0, 0,
//                                                  width, height, depth),
//                          mipmapLevel: 0,
//                          slice: 0,
//                          withBytes: gradientData,
//                          bytesPerRow: Float.size * channel * width,
//                          bytesPerImage: width * height * Float.size * channel)
//
//        gradientData.deallocate()
//        values.deallocate()
//
//        return (texture!, gradient!)
    }
    
    static func getHead(device: MTLDevice) -> MTLTexture {
        let width = 512
        let height = 512
        let depth = 511
        let channel = 1
        
        let values = UnsafeMutablePointer<Float>
            .allocate(capacity: width * height * depth * channel)
        
        for i in 0 ..< depth {
            let ptr = values.advanced(by: width * height * channel * i)
            let name = String(format: "Head%04d", arguments: [i])
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
        
        return texture!
    }
}
