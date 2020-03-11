//
//  AVCaptureBufferDelegate.swift
//  LiveDetection
//
//  Created by Jake on 3/9/20.
//  Copyright © 2020 Jake. All rights reserved.
//

import AVKit
import UIKit
import SwiftUI

struct AVCaptureBufferDelegate: UIViewControllerRepresentable {
    @Binding var recordingActive: Bool
    @Binding var readyToAnalyze: Bool
    @Binding var videoOutput: AVCaptureVideoDataOutput
    @Binding var predictions: Set<String>
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIViewController(context: Context) -> UIViewController {
        let vc = UIViewController()
        return vc
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        
    }

    class Coordinator: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
        var parent: AVCaptureBufferDelegate
        var context = CIContext()
        var model = SqueezeNet()
        
        init(_ bufferDelegate: AVCaptureBufferDelegate) {
            self.parent = bufferDelegate
            super.init()
            self.parent.videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue.main)
        }
        
        func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
            guard self.parent.recordingActive else { return }
            guard CMSampleBufferDataIsReady(sampleBuffer) == true else { return }
            guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
            
            guard self.parent.readyToAnalyze else { return }
            self.parent.readyToAnalyze = false
            
            DispatchQueue.global().async {
                let inputSize = CGSize(width: 227.0, height: 227.0)
                let image = CIImage(cvImageBuffer: pixelBuffer)
                
                guard let resizedPixelBuffer = image.pixelBuffer(at: inputSize, context: self.context) else { return }
                
                let prediction = try? self.model.prediction(image: resizedPixelBuffer)
                
                let predictionName = prediction?.classLabel ?? "Unknown"
                
                self.parent.predictions.insert(predictionName)
                
                self.parent.readyToAnalyze = true
            }
        }
    }
}

extension CIImage {
    func pixelBuffer(at size: CGSize, context: CIContext) -> CVPixelBuffer? {
        let attributes = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue, kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary

        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(kCFAllocatorDefault, Int(size.width), Int(size.height), kCVPixelFormatType_32ARGB, attributes, &pixelBuffer)
        guard status == kCVReturnSuccess else { return nil }

        let scale = size.width / self.extent.size.width
        let resizedImage = self.transformed(by: CGAffineTransform(scaleX: scale, y: scale))

        let width = resizedImage.extent.width
        let height = resizedImage.extent.height
        let yOffset = (CGFloat(height) - size.height) / 2.0
        let rect = CGRect(x: (CGFloat(width) - size.width) / 2.0, y: yOffset, width: size.width, height: size.height)
        let croppedImage = resizedImage.cropped(to: rect)
        let translatedImage = croppedImage.transformed(by: CGAffineTransform(translationX: 0, y: -yOffset))

        CVPixelBufferLockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        context.render(translatedImage, to: pixelBuffer!)
        CVPixelBufferUnlockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))

        return pixelBuffer
    }
}
