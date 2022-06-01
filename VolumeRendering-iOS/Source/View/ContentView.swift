import MetalKit
import SceneKit
import SwiftUI

struct ContentView: View {
    var view = SCNView()
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            SceneView(scnView: view)
                .background(.gray)
                .onAppear(perform: {
                    SceneViewController.Instance.onAppear(view)
                })
            DrawOptionView()
                .frame(width: 300,
                       height: 400,
                       alignment: .topLeading)
                .background(.clear)
        }
    }
}

struct DrawOptionView: View {
    @State var part = VolumeCubeMaterial.BodyPart.none
    @State var preset = VolumeCubeMaterial.Preset.ct_arteries
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
                    SceneViewController.Instance.setPart(part: $0)
                    shift = 0
                }
                .foregroundColor(.orange)
                .onAppear() {
                    UISegmentedControl.appearance().selectedSegmentTintColor = .blue
                    UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
                    UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor: UIColor.blue], for: .normal)
                }
            }
            
            HStack {
                Picker("Choose a Preset", selection: $preset) {
                    ForEach(VolumeCubeMaterial.Preset.allCases, id: \.self) { part in
                        Text(part.rawValue)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                .onChange(of: preset) {
                    SceneViewController.Instance.setPreset(preset: $0)
                    shift = 0
                }
                .foregroundColor(.orange)
                .onAppear() {
                    UISegmentedControl.appearance().selectedSegmentTintColor = .blue
                    UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
                    UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor: UIColor.blue], for: .normal)
                }
            }
            
            HStack {
                Toggle("Lighting On",
                       isOn: $lightingOn)
                .foregroundColor(.white)
                .onChange(of: lightingOn,
                          perform: SceneViewController.Instance.setLighting)
            }
            
            HStack {
                Text("Step")
                    .foregroundColor(.white)
                
                Slider(value: $step, in: 128...512, step: 1)
                    .padding()
                    .onChange(of: step, perform: SceneViewController.Instance.setStep)
            }
            
            HStack {
                Text("Shift")
                    .foregroundColor(.white)
                Slider(value: $shift, in: -100...100, step: 1)
                    .padding()
                    .onChange(of: shift, perform: SceneViewController.Instance.setShift)
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
