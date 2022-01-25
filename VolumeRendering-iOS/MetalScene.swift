//
//  MetalScene.swift
//  VolumeRendering-iOS
//
//  Created by skia on 2022/01/24.
//

import MetalKit
import SwiftUI

struct MetalScene: UIViewRepresentable {
    typealias UIViewType = MTKView
    var mtkView: MTKView
    
    class Coordinator: Renderer {}
    
    func makeCoordinator() -> Coordinator {
        mtkView.device = MTLCreateSystemDefaultDevice()
        mtkView.clearColor = .init(red: 0.7, green: 0.7, blue: 0.7, alpha: 0.7)
        mtkView.colorPixelFormat = .bgra8Unorm
        mtkView.depthStencilPixelFormat = .depth32Float
        mtkView.backgroundColor = .lightGray
        return Coordinator(mtkView)
    }
    
    func makeUIView(context: Context) -> MTKView {
        mtkView.delegate = context.coordinator
        return mtkView
    }
    
    func updateUIView(_ uiView: MTKView, context: Context) {
        uiView.draw(uiView.frame)
    }
}
