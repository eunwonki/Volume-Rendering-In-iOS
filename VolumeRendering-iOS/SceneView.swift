import SceneKit
import MetalKit
import SwiftUI

struct SceneView: UIViewRepresentable {
    typealias UIViewType = SCNView
    var scnView: SCNView
    
    func makeUIView(context: Context) -> SCNView {
        let scene = SCNScene()
        let root = scene.rootNode
        let device = scnView.device!
        
        scnView.allowsCameraControl = true
        scnView.autoenablesDefaultLighting = true
        scnView.showsStatistics = true
        scnView.backgroundColor = .lightGray
        
        let cameraController = scnView.defaultCameraController
        
        let box = SCNBox(width: 1, height: 1, length: 1, chamferRadius: 0)
        box.materials = [VolumeCubeMaterial(device: device)]
        let node = SCNNode(geometry: box)
        node.position = SCNVector3Make(0, 0, 2)
        root.addChildNode(node)
        
        let node2 = SCNNode(geometry: SCNBox(width: 1, height: 1, length: 1, chamferRadius: 0))
        node2.geometry?.firstMaterial?.diffuse.contents = UIColor.yellow
        node2.position = SCNVector3Make(2, 0, 2)
        root.addChildNode(node2)
        
        let node3 = SCNNode(geometry: SCNBox(width: 1, height: 1, length: 1, chamferRadius: 0))
        node3.geometry?.firstMaterial?.diffuse.contents = UIColor.green
        node3.position = SCNVector3Make(-2, 0, 2)
        root.addChildNode(node3)
        
        cameraController.target = SCNVector3Make(0, 0, 2)
        
        scnView.scene = scene
        
        return scnView
    }
    
    func updateUIView(_ uiView: SCNView, context: Context) {
    }
}
