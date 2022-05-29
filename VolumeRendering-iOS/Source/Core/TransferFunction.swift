import Foundation
import Metal
import simd

struct TransferFunction: Codable
{
    var version: Int?
    var name: String = ""
    var colourPoints: [ColorPoint] = []
    var alphaPoints: [AlphaPoint] = []
    
    var min: Float = -1024
    var max: Float = 3071
    var shift: Float = 0
    
    static func load(from: URL) -> TransferFunction
    {
        let data = try! Data(contentsOf: from)
        return try! JSONDecoder().decode(TransferFunction.self, from: data)
    }
    
    func get(device: MTLDevice) -> MTLTexture
    {
        let TEXTURE_WIDTH = 512
        let TEXTURE_HEIGHT = 2
        
        var tfCols = [RGBAColor].init(repeating: RGBAColor(), count: TEXTURE_WIDTH * TEXTURE_HEIGHT)
        
        // sort
        var cols = colourPoints.sorted(by: { $0.dataValue < $1.dataValue })
        var alps = alphaPoints.sorted(by: { $0.dataValue < $1.dataValue })
        
        // apply shift
        cols = cols.map { var tmp = $0; tmp.dataValue += shift; return tmp }
        alps = alps.map { var tmp = $0; tmp.dataValue += shift; return tmp }
        
        // add beginning and end
        if cols.count == 0 || cols.last!.dataValue < max
        {
            cols.append(ColorPoint(dataValue: min, colourValue: RGBAColor(r: 1, g: 1, b: 1, a: 1)))
        }
        if cols.first!.dataValue > min
        {
            cols.insert(ColorPoint(dataValue: max, colourValue: RGBAColor(r: 1, g: 1, b: 1, a: 1)), at: 0)
        }
        
        if alps.count == 0 || alps.last!.dataValue < max
        {
            alps.append(AlphaPoint(dataValue: min, alphaValue: 1))
        }
        if alps.first!.dataValue > min
        {
            alps.insert(AlphaPoint(dataValue: max, alphaValue: 0), at: 0)
        }
        
        var iCurrColor = 0
        var iCurrAlpha = 0
        
        for ix in 0 ..< TEXTURE_WIDTH
        {
            let t = Float(ix) / Float(TEXTURE_WIDTH - 1)
            while iCurrColor < cols.count - 2,
                  normalize(cols[iCurrColor + 1].dataValue) < t
            {
                iCurrColor += 1
            }
            while iCurrAlpha < alps.count - 2,
                  normalize(alps[iCurrAlpha + 1].dataValue) < t
            {
                iCurrAlpha += 1
            }
            
            let leftCol = cols[iCurrColor]
            let rightCol = cols[iCurrColor + 1]
            let leftAlp = alps[iCurrAlpha]
            let rightAlp = alps[iCurrAlpha + 1]

            let tCol = normalize((simd_clamp(t, leftCol.dataValue, rightCol.dataValue) - leftCol.dataValue) / (rightCol.dataValue - leftCol.dataValue))
            let tAlp = normalize((simd_clamp(t, leftAlp.dataValue, rightAlp.dataValue) - leftAlp.dataValue) / (rightAlp.dataValue - leftAlp.dataValue))
            
            var pixCol = rightCol.colourValue * Float(tCol) + leftCol.colourValue * Float(1 - tCol)
            pixCol.a = rightAlp.alphaValue * tAlp + leftAlp.alphaValue * (1 - tAlp)
            
            for iy in 0 ..< TEXTURE_HEIGHT
            {
                tfCols[ix + iy * TEXTURE_WIDTH] = pixCol
            }
        }
        
        let textureDescriptor = MTLTextureDescriptor()
        textureDescriptor.textureType = .type2D
        textureDescriptor.pixelFormat = .rgba32Float
        textureDescriptor.width = TEXTURE_WIDTH
        textureDescriptor.height = TEXTURE_HEIGHT
        textureDescriptor.usage = .shaderRead
        
        let texture = device.makeTexture(descriptor: textureDescriptor)
        texture?.replace(region: MTLRegionMake2D(0, 0, TEXTURE_WIDTH, TEXTURE_HEIGHT),
                         mipmapLevel: 0,
                         slice: 0,
                         withBytes: tfCols,
                         bytesPerRow: RGBAColor.size * TEXTURE_WIDTH,
                         bytesPerImage: TEXTURE_WIDTH * TEXTURE_HEIGHT * RGBAColor.size)
        
        return texture!
    }
    
    func normalize(_ value: Float) -> Float
    {
        return (value - min) / (max - min)
    }
}

struct RGBAColor: Codable, sizeable
{
    var r: Float = 0
    var g: Float = 0
    var b: Float = 0
    var a: Float = 0
}

struct ColorPoint: Codable
{
    var dataValue: Float = 0
    var colourValue: RGBAColor = .init()
}

struct AlphaPoint: Codable
{
    var dataValue: Float = 0
    var alphaValue: Float = 0
}

func * (color: RGBAColor, value: Float) -> RGBAColor
{
    return RGBAColor(r: color.r * value, g: color.g * value, b: color.b * value, a: color.a * value)
}

func + (a: RGBAColor, b: RGBAColor) -> RGBAColor
{
    return RGBAColor(r: a.r + b.r, g: a.g + b.g, b: a.b + b.b, a: a.a + b.a)
}
