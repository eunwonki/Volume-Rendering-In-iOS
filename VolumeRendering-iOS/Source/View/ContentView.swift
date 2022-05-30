import MetalKit
import SceneKit
import SwiftUI

var vc = SceneViewController() // TODO: 전역변수가 아니도록 개선 필요...

struct ContentView: View {
    var view = SCNView()
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            SceneView(scnView: view)
                .background(.gray)
                .onAppear(perform: {
                    vc.onAppear(view)
                })
            DrawOptionView()
                .frame(width: 250,
                       height: 200,
                       alignment: .topLeading)
                .background(.clear)
        }
    }
}

struct DrawOptionView: View {
    @State var part = VolumeCubeMaterial.BodyPart.none
    @State var lightingOn: Bool = true
    @State var step: Float = 512
    @State var shift: Float = 0
    
    var body: some View {
        VStack {
            HStack {
                Picker("Choose a Part", selection: $part) {
                    ForEach(VolumeCubeMaterial.BodyPart.allCases, id: \.self) { part in
                        Text(part.rawValue)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                .onChange(of: part) {
                    vc.onInit(part: $0)
                }
            }
            
            HStack {
                Toggle("Lighting On",
                       isOn: $lightingOn)
            }
            
            HStack {
                Text("Step")
                    .foregroundColor(.white)
                
                Slider(value: $step, in: 128...512, step: 1)
                    .padding()
            }
            
            HStack {
                Text("Shift")
                    .foregroundColor(.white)
                Slider(value: $shift, in: -100...100, step: 1)
                    .padding()
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .previewInterfaceOrientation(.landscapeRight)
            .previewDevice("iPad Pro (11-inch) (3rd generation)")
    }
}
