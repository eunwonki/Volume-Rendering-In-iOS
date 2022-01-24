import SwiftUI
import MetalKit

struct ContentView: View {
    var body: some View {
        MetalScene(mtkView: MTKView())
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
