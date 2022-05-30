import MetalKit
import SceneKit
import SwiftUI

struct SceneView: UIViewRepresentable {
    typealias UIViewType = SCNView
    var scnView: SCNView
    
    func makeUIView(context: Context) -> SCNView {
        let scene = SCNScene()
        scnView.allowsCameraControl = true
        scnView.autoenablesDefaultLighting = true
        scnView.showsStatistics = true
        scnView.backgroundColor = .black
        
        scnView.scene = scene        
        return scnView
    }
    
    func updateUIView(_ uiView: SCNView, context: Context) {}
}
