//
//  CapturePreviewView.swift
//  LiveDetection
//
//  Created by Jake on 3/7/20.
//  Copyright © 2020 Jake. All rights reserved.
//

import AVKit
import UIKit
import SwiftUI

class CapturePreviewViewClass: UIView {
    override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }
}

struct CapturePreviewView: UIViewRepresentable {
    @Binding var session: AVCaptureSession
    
    func makeUIView(context: Context) -> UIView {
        let captureView = CapturePreviewViewClass()
        let previewLayer = captureView.layer as! AVCaptureVideoPreviewLayer
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        previewLayer.session = session
        return captureView
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        
    }
}

