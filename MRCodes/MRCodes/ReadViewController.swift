//
//  ViewController.swift
//  MRCodes
//
//  Created by larryhou on 13/12/2015.
//  Copyright © 2015 larryhou. All rights reserved.
//

import UIKit
import AVFoundation

class ReadViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate
{
    @IBOutlet weak var previewView: CameraPreviewView!
    @IBOutlet weak var overlay: CameraOverlayView!
    
    private var session:AVCaptureSession!
    private var metadataQueue:dispatch_queue_t!

    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        session = AVCaptureSession()
        session.sessionPreset = AVCaptureSessionPresetPhoto
        previewView.session = session
        (previewView.layer as! AVCaptureVideoPreviewLayer).videoGravity = AVLayerVideoGravityResizeAspectFill
        
        metadataQueue = dispatch_queue_create("MetadataOutput", DISPATCH_QUEUE_SERIAL)
        
        AVCaptureDevice.requestAccessForMediaType(AVMediaTypeVideo)
        { (success:Bool) -> Void in
            let status = AVCaptureDevice.authorizationStatusForMediaType(AVMediaTypeVideo)
            if success
            {
                self.configSession()
            }
            else
            {
                print(status, status.rawValue)
            }
        }
    }
    
    func findCamera(position:AVCaptureDevicePosition)->AVCaptureDevice!
    {
        let list = AVCaptureDevice.devices() as! [AVCaptureDevice]
        for device in list
        {
            if device.position == position
            {
                return device
            }
        }
        
        return nil
    }
    
    func configSession()
    {
        session.beginConfiguration()
        
        let camera = findCamera(.Back)
        do
        {
            let cameraInput = try AVCaptureDeviceInput(device: camera)
            if session.canAddInput(cameraInput)
            {
                session.addInput(cameraInput)
            }
            
            setupCamera(camera)
        }
        catch {}
        
        let metadata = AVCaptureMetadataOutput()
        if session.canAddOutput(metadata)
        {
            session.addOutput(metadata)
            metadata.setMetadataObjectsDelegate(self, queue: metadataQueue)
            metadata.metadataObjectTypes = metadata.availableMetadataObjectTypes
            print(metadata.availableMetadataObjectTypes)
        }
        
        session.commitConfiguration()
        session.startRunning()
    }
    
    func setupCamera(camera:AVCaptureDevice)
    {
        do
        {
            try camera.lockForConfiguration()
        }
        catch
        {
            return
        }
        
        if camera.isFocusModeSupported(.ContinuousAutoFocus)
        {
            camera.focusMode = .ContinuousAutoFocus
        }
        
        if camera.autoFocusRangeRestrictionSupported
        {
            camera.autoFocusRangeRestriction = .Near
        }
        
        if camera.smoothAutoFocusSupported
        {
            camera.smoothAutoFocusEnabled = false
        }
        
        camera.unlockForConfiguration()
    }
    
    //MARK: metadataObjects processing
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [AnyObject]!, fromConnection connection: AVCaptureConnection!)
    {
        var codes:[AVMetadataMachineReadableCodeObject] = []
        var faces:[AVMetadataFaceObject] = []
        
        let layer = previewView.layer as! AVCaptureVideoPreviewLayer
        for item in metadataObjects as! [AVMetadataObject]
        {
            let mrc = layer.transformedMetadataObjectForMetadataObject(item)
            switch mrc
            {
                case is AVMetadataMachineReadableCodeObject:
                    codes.append(mrc as! AVMetadataMachineReadableCodeObject)
                    print("MRC", item)
                
                case is AVMetadataFaceObject:
                    faces.append(mrc as! AVMetadataFaceObject)
                
                default:
                    print(mrc)
            }
        }
        
        dispatch_async(dispatch_get_main_queue())
        {
            self.overlay.setMetadataObjects(codes, faces: faces)
        }
    }
    
    //MARK: orientation
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator)
    {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        
        let orientation = UIDevice.currentDevice().orientation
        if orientation.isLandscape || orientation.isPortrait
        {
            (previewView.layer as! AVCaptureVideoPreviewLayer).connection.videoOrientation = AVCaptureVideoOrientation(rawValue: orientation.rawValue)!
        }
    }
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask
    {
        return .All
    }

    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
    }

}

