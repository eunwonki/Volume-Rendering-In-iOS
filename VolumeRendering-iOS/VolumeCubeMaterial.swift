import SceneKit

class VolumeCubeMaterial: SCNMaterial {
    let quality = 256
    
    init(device: MTLDevice) {
        super.init()
        
        let program = SCNProgram()
        program.vertexFunctionName = "vertex_func"
        program.fragmentFunctionName = "fragment_func"
        self.program = program
        
        let texture = VolumeTexture.get(device: device)!
        let property = SCNMaterialProperty(contents: texture)
        setValue(property, forKey: "volume")
        
        setValue(quality, forKey: "quality")
        
        writesToDepthBuffer = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
