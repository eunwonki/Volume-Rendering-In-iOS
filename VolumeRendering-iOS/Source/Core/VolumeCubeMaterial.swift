import SceneKit
import SwiftUI

class VolumeCubeMaterial: SCNMaterial {
    enum Preset: String, CaseIterable, Identifiable {
        var id: RawValue { rawValue }
        case ct_arteries, ct_entire, ct_lung
    }

    enum Method: Int32 {
        case surf, dvr, mip
    }

    enum BodyPart: String, CaseIterable, Identifiable {
        var id: RawValue { rawValue }
        case none, chest, head
    }
    
    struct Uniforms: sizeable {
        var isLightingOn: Bool = true
        let method: Int32 = Method.dvr.rawValue
        var renderingQuality: Int32 = 512
        // Int16 type size mismatches in metal shader... so I use Int32.
        var voxelMinValue: Int32 = -1024
        var voxelMaxValue: Int32 = 3071
    }
    
    var uniform = Uniforms()
    var textureGenerator: VolumeTextureFactory!
    var tf: TransferFunction?
    
    var scale: float3 { textureGenerator.scale }
    
    init(device: MTLDevice) {
        super.init()
        
        let program = SCNProgram()
        program.vertexFunctionName = "volume_vertex"
        program.fragmentFunctionName = "volume_fragment"
        self.program = program
        
        setPart(device: device, part: .none)
        
        setPreset(device: device, preset: .ct_arteries)
        setShift(device: device, shift: 0)
        
        let buffer = NSData(bytes: &uniform, length: Uniforms.size)
        setValue(buffer, forKey: "uniforms")
        
        cullMode = .front
        writesToDepthBuffer = true
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setPart(device: MTLDevice, part: BodyPart) {
        textureGenerator = VolumeTextureFactory(part)
        
        let tProperty = SCNMaterialProperty(contents: textureGenerator.generate(device: device) as Any)
        setValue(tProperty, forKey: "dicom")
    }
    
    func setPreset(device: MTLDevice, preset: Preset) {
        let url = Bundle.main.url(forResource: preset.rawValue, withExtension: "tf")!
        tf = TransferFunction.load(from: url)
    }
    
    func setLighting(on: Bool) {
        uniform.isLightingOn = on
        let buffer = NSData(bytes: &uniform, length: Uniforms.size)
        setValue(buffer, forKey: "uniforms")
    }
    
    func setStep(step: Float) {
        uniform.renderingQuality = Int32(step)
        let buffer = NSData(bytes: &uniform, length: Uniforms.size)
        setValue(buffer, forKey: "uniforms")
    }
    
    func setShift(device: MTLDevice, shift: Float) {
        tf?.shift = shift
        guard let tf = tf else { return }
        let tfTexture = tf.get(device: device)
        let tfProperty = SCNMaterialProperty(contents: tfTexture)
        setValue(tfProperty, forKey: "transferColor")
    }
}
