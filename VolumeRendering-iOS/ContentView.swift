import SwiftUI
import MetalKit

struct ContentView: View {
    let drag = DragGesture()
        .onChanged {
            Gesture.OnDragging(start: $0.startLocation,
                               translation: $0.translation)
        }
        .onEnded { _ in
            Gesture.OnDragEnd()
        }
    
    var body: some View {
        MetalScene(mtkView: MTKView())
            .gesture(drag)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
