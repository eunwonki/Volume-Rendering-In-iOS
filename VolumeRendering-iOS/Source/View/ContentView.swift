import MetalKit
import SceneKit
import SwiftUI

struct ContentView: View {
    var view = SCNView()
    
    @State var showOption = true
    @StateObject var model = DrawOptionModel()
    
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
                    DrawOptionView(
                        model: model).background(.clear)
                }
            }.padding(.vertical, 25)
        }
    }
}

class DrawOptionModel: ObservableObject {
    @Published var part = VolumeCubeMaterial.BodyPart.none
    @Published var method = VolumeCubeMaterial.Method.dvr
    @Published var preset = VolumeCubeMaterial.Preset.ct_arteries
    @Published var lightingOn: Bool = true
    @Published var step: Float = 512
    @Published var shift: Float = 0
}

struct DrawOptionView: View {
    @ObservedObject var model: DrawOptionModel
    
    var body: some View {
        VStack (spacing: 10) {
            HStack {
                Picker("Choose a method", selection: $model.method) {
                    ForEach(VolumeCubeMaterial.Method.allCases, id: \.self) { part in
                        Text(part.rawValue)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                .onChange(of: model.method) {
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
                Picker("Choose a Part", selection: $model.part) {
                    ForEach(VolumeCubeMaterial.BodyPart.allCases, id: \.self) { part in
                        Text(part.rawValue)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                .onChange(of: model.part) {
                    SceneViewController.Instance.setPart(part: $0)
                    model.shift = 0
                }
                .foregroundColor(.orange)
                .onAppear() {
                    UISegmentedControl.appearance().selectedSegmentTintColor = .blue
                    UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
                    UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor: UIColor.blue], for: .normal)
                }
            }.frame(height: 30)
            
            HStack {
                Picker("Choose a Preset", selection: $model.preset) {
                    ForEach(VolumeCubeMaterial.Preset.allCases, id: \.self) { part in
                        Text(part.rawValue)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                .onChange(of: model.preset) {
                    SceneViewController.Instance.setPreset(preset: $0)
                    model.shift = 0
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
                       isOn: $model.lightingOn)
                .foregroundColor(.white)
                .onChange(of: model.lightingOn,
                          perform: SceneViewController.Instance.setLighting)
            }.frame(height: 30)
            
            HStack {
                Text("Step")
                    .foregroundColor(.white)
                
                Slider(value: $model.step, in: 128...512, step: 1)
                    .padding()
                    .onChange(of: model.step, perform: SceneViewController.Instance.setStep)
            }.frame(height: 30)
            
            HStack {
                Text("Shift")
                    .foregroundColor(.white)
                Slider(value: $model.shift, in: -100...100, step: 1)
                    .padding()
                    .onChange(of: model.shift, perform: SceneViewController.Instance.setShift)
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
