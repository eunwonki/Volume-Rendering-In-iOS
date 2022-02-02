import SceneKit
import SwiftUI

enum Preset: String {
    case preset1, preset2, preset3, CT_Coronary_Arteries_2, CT_Lung
}

enum Method: Int32 {
    case surf, dvr, mip
}

enum BodyPart {
    case chest, head
}

class VolumeCubeMaterial: SCNMaterial {
    struct Uniforms: sizeable {
        let method: Int32 = Method.dvr.rawValue
        let renderingQuality: Int32 = 512
    }
    
    let quality = 512
    let bodyPart: BodyPart = .head
    let preset: Preset = .CT_Coronary_Arteries_2
    var uniform = Uniforms()
    
    static let CHEST_SCALE = float3(0.431, 0.431, 0.322)
    static let HEAD_SCALE = float3(0.23, 0.23, 0.511)
    
    var scale: float3 {
        if bodyPart == .chest { return VolumeCubeMaterial.CHEST_SCALE }
        else { return VolumeCubeMaterial.HEAD_SCALE }
    }
    
    init(device: MTLDevice) {
        super.init()
        
        let program = SCNProgram()
        program.vertexFunctionName = "vertex_func"
        program.fragmentFunctionName = "fragment_func"
        self.program = program
        
        let texture = bodyPart == .chest
            ? VolumeTexture.getChest(device: device)
            : VolumeTexture.getHead(device: device)
        let tProperty = SCNMaterialProperty(contents: texture)
        setValue(tProperty, forKey: "volume")
        // let gProperty = SCNMaterialProperty(contents: gradient)
        // setValue(gProperty, forKey: "gradient")
        
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
