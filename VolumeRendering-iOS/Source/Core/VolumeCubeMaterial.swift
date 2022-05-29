import SceneKit
import SwiftUI

class VolumeCubeMaterial: SCNMaterial {
    enum Preset: String {
        case ct_arteries, ct_entire, ct_lung
    }

    enum Method: Int32 {
        case surf, dvr, mip
    }

    enum BodyPart {
        case chest, head
    }
    
    struct Uniforms: sizeable {
        var isLightingOn: Bool = true
        let method: Int32 = Method.dvr.rawValue
        var renderingQuality: Int32 = 128
        // Int16 type size mismatches in metal shader... so I use Int32.
        var voxelMinValue: Int32 = -1024
        var voxelMaxValue: Int32 = 3071
    }
    
    let bodyPart: BodyPart = .head
    let preset: Preset = .ct_arteries
    var uniform = Uniforms()
    var textureGenerator: VolumeTextureFactory
    
    var scale: float3 { textureGenerator.scale }
    
    init(device: MTLDevice) {
        textureGenerator = VolumeTextureFactory(bodyPart)
        
        super.init()
        
        let program = SCNProgram()
        program.vertexFunctionName = "volume_vertex"
        program.fragmentFunctionName = "volume_fragment"
        self.program = program
        
        let tProperty = SCNMaterialProperty(contents: textureGenerator.generate(device: device))
        setValue(tProperty, forKey: "dicom")
        
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