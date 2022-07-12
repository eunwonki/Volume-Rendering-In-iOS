//
//  SceneViewController.swift
//  VolumeRendering-iOS
//
//  Created by won on 2022/05/30.
//

import Foundation
import SceneKit

class SceneViewController: NSObject {
    static let Instance = SceneViewController() // like Singleton
    
    var device: MTLDevice!
    var root: SCNNode!
    var cameraController: SCNCameraController!
    
    var volume: SCNNode!
    var mat: VolumeCubeMaterial!
    
    override public init() { super.init() }
    
    func onAppear(_ view: SCNView) {
        device = view.device!
        root = view.scene!.rootNode
        cameraController = view.defaultCameraController
        
        let box = SCNBox(width: 1, height: 1, length: 1, chamferRadius: 0)
        mat = VolumeCubeMaterial(device: device)
        mat.setPart(device: device, part: .none)
        volume = SCNNode(geometry: box)
        volume.geometry?.materials = [mat]
        volume.scale = SCNVector3(mat.scale)
        root.addChildNode(volume)
        
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
        
        cameraController.target = volume.boundingSphere.center
    }
    
    func setMethod(method: VolumeCubeMaterial.Method) {
        mat.setMethod(method: method)
    }
    
    func setPart(part: VolumeCubeMaterial.BodyPart) {
        mat.setPart(device: device, part: part)
        volume.geometry?.materials = [mat]
        mat.setShift(device: device, shift: 0)
    }
    
    func setPreset(preset: VolumeCubeMaterial.Preset) {
        mat.setPreset(device: device, preset: preset)
        mat.setShift(device: device, shift: 0)
    }
    
    func setLighting(isOn: Bool) {
        mat.setLighting(on: isOn)
    }
    
    func setStep(step: Float) {
        mat.setStep(step: step)
    }
    
    func setShift(shift: Float) {
        mat.setShift(device: device, shift: shift)
    }
}
