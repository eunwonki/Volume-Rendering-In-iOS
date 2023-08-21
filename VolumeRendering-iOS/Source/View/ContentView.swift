import MetalKit
import SceneKit
import SwiftUI

struct ContentView: View {
    var view = SCNView()
    
    @State var showOption = true
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            SceneView(scnView: view)
                .background(.gray)
                .onAppear(perform: {
                    SceneViewController.Instance.onAppear(view)
                })
               
            HStack(alignment: .top) {
                Button(showOption ? "hide" : "show") {
                    showOption.toggle()
                }
                
                if showOption {
                    DrawOptionView().background(.clear)
                }
            }.padding(.vertical, 25)
        }
    }
}

struct DrawOptionView: View {
    @State var part = VolumeCubeMaterial.BodyPart.none
    @State var method = VolumeCubeMaterial.Method.dvr
    @State var preset = VolumeCubeMaterial.Preset.ct_arteries
    @State var lightingOn: Bool = true
    @State var step: Float = 512
    @State var shift: Float = 0
    
    var body: some View {
        VStack (spacing: 10) {
            HStack {
                Picker("Choose a method", selection: $method) {
                    ForEach(VolumeCubeMaterial.Method.allCases, id: \.self) { part in
                        Text(part.rawValue)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                .onChange(of: method) {
                    SceneViewController.Instance.setMethod(method: $0)
                }
                .foregroundColor(.orange)
                .onAppear() {
                    UISegmentedControl.appearance().selectedSegmentTintColor = .blue
                    UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
                    UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor: UIColor.blue], for: .normal)
                }
            }.frame(height: 30)
            
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
            }.frame(height: 30)
            
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
            }.frame(height: 30)
            
            HStack {
                Toggle("Lighting On",
                       isOn: $lightingOn)
                .foregroundColor(.white)
                .onChange(of: lightingOn,
                          perform: SceneViewController.Instance.setLighting)
            }.frame(height: 30)
            
            HStack {
                Text("Step")
                    .foregroundColor(.white)
                
                Slider(value: $step, in: 128...512, step: 1)
                    .padding()
                    .onChange(of: step, perform: SceneViewController.Instance.setStep)
            }.frame(height: 30)
            
            HStack {
                Text("Shift")
                    .foregroundColor(.white)
                Slider(value: $shift, in: -100...100, step: 1)
                    .padding()
                    .onChange(of: shift, perform: SceneViewController.Instance.setShift)
            }.frame(height: 30)
            
            Spacer()
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
