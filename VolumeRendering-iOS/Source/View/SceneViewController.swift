//
//  SceneViewController.swift
//  VolumeRendering-iOS
//
//  Created by won on 2022/05/30.
//

import Foundation
import SceneKit

class SceneViewController: NSObject {
    var device: MTLDevice!
    var root: SCNNode!
    var cameraController: SCNCameraController!
    
    override public init() { super.init() }
    
    func onAppear(_ view: SCNView) {
        device = view.device!
        root = view.scene!.rootNode
        cameraController = view.defaultCameraController
    }
    
    func onInit(part: VolumeCubeMaterial.BodyPart) {
        let box = SCNBox(width: 1, height: 1, length: 1, chamferRadius: 0)
        let material = VolumeCubeMaterial(device: device, part: part)
        box.materials = [material]
        let node = SCNNode(geometry: box)
        node.scale = SCNVector3(material.scale)
        root.addChildNode(node)
        
//        // for depth test
//        let node2 = SCNNode(geometry: SCNBox(width: 0.2, height: 0.2, length: 0.2, chamferRadius: 0))
//        node2.geometry?.firstMaterial?.diffuse.contents = UIColor.yellow
//        node2.position = SCNVector3Make(0.5, 0, 0.5)
//        root.addChildNode(node2)
//
//        let node3 = SCNNode(geometry: SCNSphere(radius: 0.2))
//        node3.geometry?.firstMaterial?.diffuse.contents = UIColor.green
//        node3.position = SCNVector3Make(-0.5, 0, 0.5)
//        root.addChildNode(node3)
                
        cameraController.target = node.boundingSphere.center
    }
}
