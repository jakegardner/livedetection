//
//  ContentView.swift
//  LiveDetection
//
//  Created by Jake on 3/7/20.
//  Copyright © 2020 Jake. All rights reserved.
//

import SwiftUI
import AVKit

enum SetupError : Error {
    case noVideoDevice, videoInputFailed, videoOutputFailed
}

struct ContentView: View {
    @State private var session = AVCaptureSession()
    @State private var videoOutput = AVCaptureVideoDataOutput()
    @State private var recordingActive = true
    @State private var readyToAnalyze = true
    @State var predictions: Set<String> = []
    
    @State var showingResults = false
    
    func startRecording() {
        recordingActive = true
        session.startRunning()
    }
    
    func stopRecording() {
        recordingActive = false
        session.stopRunning()
    }

    func configureVideoDeviceInput() throws {
        guard let videoCaptureDevice = AVCaptureDevice.default(for: AVMediaType.video) else {
            throw SetupError.noVideoDevice
        }
        
        let videoDeviceInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        
        if session.canAddInput(videoDeviceInput) {
            session.addInput(videoDeviceInput)
        } else {
            throw SetupError.videoInputFailed
        }
    }
    
    func configureVideoDeviceOutput() throws {
        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
            
            for connection in videoOutput.connections {
                for port in connection.inputPorts {
                    if port.mediaType == .video {
                        connection.videoOrientation = .portrait
                    }
                }
            }
        } else {
            throw SetupError.videoOutputFailed
        }
    }
    
    func configureSession() throws {
        session.beginConfiguration()
        try configureVideoDeviceInput()
        try configureVideoDeviceOutput()
        session.commitConfiguration()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                AVCaptureBufferDelegate(recordingActive: self.$recordingActive, readyToAnalyze: self.$readyToAnalyze, videoOutput: self.$videoOutput, predictions: self.$predictions)
                CapturePreviewView(session: self.$session).onAppear {
                    do {
                        try self.configureSession()
                        self.startRecording()
                    } catch {
                        print("AVSession configuration failed")
                    }
                }
            }
            Button(action: {
                self.showingResults.toggle()
            }) {
                Text("Results")
            }
            .padding(10)
            .sheet(isPresented: $showingResults) {
                ResultsView(predictions: self.$predictions)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
