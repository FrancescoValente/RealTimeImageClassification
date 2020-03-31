//
//  ViewController.swift
//  RealTimeImageClassification
//
//  Created by Francesco Valente on 30/03/2020.
//  Copyright © 2020 Francesco Valente. All rights reserved.
//

import UIKit
import AVKit
import Vision

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    @IBOutlet weak var predictionLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //here we initialize the object AVCaptureSession that manages the capture activity
        let session = AVCaptureSession()
        session.sessionPreset = .photo
        
        guard let captureDevice = AVCaptureDevice.default(for: .video) else {
            fatalError("AVCaptureDevice failed")
        }
        
        guard let input = try? AVCaptureDeviceInput(device: captureDevice)
            else{
            fatalError("AVCaptureDeviceInput failed")
            }
        
        //the caputure session needs an input to capture(audio or video) --> see the previous set up
        session.addInput(input)
        
        session.startRunning()
        
        //here we want to tell the application to show us the output of the camera
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        view.layer.addSublayer(previewLayer)
        //here we specify the frame
        previewLayer.frame = view.frame
        
        
        //here we want to access to the camera frame which is the output of the camera
        let dataOutput = AVCaptureVideoDataOutput()
        //we want to monitor each frame captured
        dataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        //we add the dataOutput to the capture session
        session.addOutput(dataOutput)
    }
    
    
    //this method is called every time a new video frame is captured by the camera: inside this method we will perform the analysis of the frame
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection){
        
        //here we create our model object as VNCoreMLModel which is a container fot our ML model
        guard let model = try? VNCoreMLModel(for: DaenerysAndJonClassifier().model)
            else{
            fatalError("Loading CoreML model failed")
        }
        //here we initialize the CoreMLRequest object
        let request = VNCoreMLRequest(model: model)
        { (finishedReq, err) in
            //here we process the results of the request
            guard let results = finishedReq.results as? [VNClassificationObservation] else { return }
            
            guard let firstObservation = results.first else { return }
            
            DispatchQueue.main.async {
                self.predictionLabel.text = firstObservation.identifier
            }
            
        }
        
        guard let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
            else {
            fatalError("CMSapleBufferGetImageBuffer failed")
        }
        
        //Notice that this Request Handler needs an input parameter of type CVPixelBuffer so we need to convert the camera frame into a CVPixelBuffer that Request Handler can process
        try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]).perform([request])
    }

}

