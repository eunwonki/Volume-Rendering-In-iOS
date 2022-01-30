import SceneKit
import SwiftUI

enum Preset: String {
    case preset1, preset2, preset3, preset4
}

enum Method: Int32 {
    case surf, dvr, mip
}

class VolumeCubeMaterial: SCNMaterial {
    struct Uniforms: sizeable {
        let method: Int32 = Method.surf.rawValue
        let renderingQuality: Int32 = 512
    }
    
    let quality = 512
    let preset: Preset = .preset1
    var uniform = Uniforms()
    
    init(device: MTLDevice) {
        super.init()
        
        let program = SCNProgram()
        program.vertexFunctionName = "vertex_func"
        program.fragmentFunctionName = "fragment_func"
        self.program = program
        
        let (texture, gradient) = VolumeTexture.get(device: device)
        let tProperty = SCNMaterialProperty(contents: texture)
        setValue(tProperty, forKey: "volume")
        let gProperty = SCNMaterialProperty(contents: gradient)
        setValue(gProperty, forKey: "gradient")
        
        let url = Bundle.main.url(forResource: preset.rawValue, withExtension: "tf")!
        let tf = TransferFunction.load(from: url)
        let tfTexture = tf.get(device: device)
        let tfProperty = SCNMaterialProperty(contents: tfTexture)
        setValue(tfProperty, forKey: "transferColor")
        
        let buffer = NSData(bytes: &uniform, length: Uniforms.size)
        setValue(buffer, forKey: "uniforms")
        
        cullMode = .front
        writesToDepthBuffer = true
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
