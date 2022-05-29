import MetalKit
import SceneKit
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
        let material = VolumeCubeMaterial(device: device)
        box.materials = [material]
        let node = SCNNode(geometry: box)
        node.scale = SCNVector3(material.scale)
        root.addChildNode(node)
        
        // for depth test
//        let node2 = SCNNode(geometry: SCNBox(width: 0.2, height: 0.2, length: 0.2, chamferRadius: 0))
//        node2.geometry?.firstMaterial?.diffuse.contents = UIColor.yellow
//        node2.position = SCNVector3Make(0.5, 0, 0.5)
//        root.addChildNode(node2)
        
//        let node3 = SCNNode(geometry: SCNSphere(radius: 0.2))
//        node3.geometry?.firstMaterial?.diffuse.contents = UIColor.green
//        node3.position = SCNVector3Make(-0.5, 0, 0.5)
//        root.addChildNode(node3)
        
        cameraController.target = node.boundingSphere.center
        
        scnView.scene = scene
        
        return scnView
    }
    
    func updateUIView(_ uiView: SCNView, context: Context) {}
}
