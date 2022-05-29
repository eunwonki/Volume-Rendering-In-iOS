import MetalKit
import SceneKit
import SwiftUI

struct ContentView: View {
    var body: some View {
        ZStack {
            SceneView(scnView: SCNView())
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
