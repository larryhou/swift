//
//  ViewController.swift
//  CarolCamera
//
//  Created by larryhou on 29/11/2015.
//  Copyright © 2015 larryhou. All rights reserved.
//

import UIKit
import AVFoundation
import MediaPlayer
import Photos

class CaptureViewController: UIViewController
{
    var CONTEXT_LENS_LENGTH:Int = 0
    var CONTEXT_ISO:Int = 0
    var CONTEXT_EXPOSURE_DURATION:Int = 0
    var CONTEXT_OUTPUT_VOLUME:Int = 0
    
    @IBOutlet var previewView: LivePreivewView!
    
    private var session:AVCaptureSession!
    private var sessionQueue:dispatch_queue_t!
    
    private var camera:AVCaptureDevice!
    private var cameraInput:AVCaptureDeviceInput!
    private var imageOutput:AVCaptureStillImageOutput!
    
    private var changeVolume:(Float)->Void = {volume in}
    
    class func deviceWithMediaType(mediaType:String, position:AVCaptureDevicePosition)->AVCaptureDevice
    {
        let devices = AVCaptureDevice.devicesWithMediaType(mediaType) as! [AVCaptureDevice]
        var target = devices.first
        
        for item in devices
        {
            if item.position == position
            {
                target = item
                break
            }
        }
        
        return target!
        
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        let volumeView = MPVolumeView(frame: CGRect(x: -100, y: 0, width: 10, height: 0))
        volumeView.sizeToFit()
        
        self.view.addSubview(volumeView)
        
        for view in volumeView.subviews
        {
            if view.dynamicType.description() == "MPVolumeSlider"
            {
                let slider = view as! UISlider
                changeVolume =
                { value in
                    dispatch_async(dispatch_get_main_queue())
                    {
                        slider.setValue(value, animated: true)
                        slider.sendActionsForControlEvents(.TouchUpInside)
                    }
                }
                break
            }
        }
        
        do
        {
            try AVAudioSession.sharedInstance().setActive(true)
        }
        catch {}
        
        if AVAudioSession.sharedInstance().outputVolume == 1.0
        {
            changeVolume(1.0 - 1.0 / 16.0)
        }
        
        AVAudioSession.sharedInstance().addObserver(self, forKeyPath: "outputVolume", options: [.New, .Old], context: &CONTEXT_OUTPUT_VOLUME)
    }
    
    override func viewDidAppear(animated: Bool)
    {
        super.viewDidAppear(animated)
        
        session = AVCaptureSession()
        previewView.session = session
        
        sessionQueue = dispatch_queue_create("CaptureSessionQueue", DISPATCH_QUEUE_SERIAL)
        
        var authorized = true
        let status = AVCaptureDevice.authorizationStatusForMediaType(AVMediaTypeVideo)
        switch status
        {
            case .NotDetermined, .Denied:
                dispatch_suspend(self.sessionQueue)
                AVCaptureDevice.requestAccessForMediaType(AVMediaTypeVideo)
                { (granted:Bool) in
                    
                    if !granted
                    {
                        authorized = false
                    }
                    
                    dispatch_resume(self.sessionQueue)
                }
            default:
                print(status, status.rawValue)
        }
        
        dispatch_async(self.sessionQueue)
        {
            if !authorized
            {
                return
            }
            
            let videoDevice = CaptureViewController.deviceWithMediaType(AVMediaTypeVideo, position: .Back)
            do
            {
                let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
                self.cameraInput = videoDeviceInput
            }
            catch
            {
                self.showAlertMessage(String(error))
                return
            }
            
            self.camera = videoDevice
            self.session.beginConfiguration()
            
            if self.session.canAddInput(self.cameraInput)
            {
                self.session.addInput(self.cameraInput)
                
                dispatch_async(dispatch_get_main_queue())
                {
                    var vedioOrientation = AVCaptureVideoOrientation.Portrait
                    
                    let deviceOrientation = UIApplication.sharedApplication().statusBarOrientation
                    if deviceOrientation != .Unknown
                    {
                        vedioOrientation = AVCaptureVideoOrientation(rawValue: deviceOrientation.rawValue)!
                    }
                    
                    (self.previewView.layer as! AVCaptureVideoPreviewLayer).connection.videoOrientation = vedioOrientation
                }
            }
            else
            {
                self.showAlertMessage("Could not add vedio input")
                return
            }
            
            let imageOutput = AVCaptureStillImageOutput()
            if self.session.canAddOutput(imageOutput)
            {
                self.session.addOutput(imageOutput)
                self.imageOutput = imageOutput
                imageOutput.outputSettings = [AVVideoCodecKey:AVVideoCodecJPEG]
                imageOutput.highResolutionStillImageOutputEnabled = true
            }
            else
            {
                self.showAlertMessage("Could not add image output")
                return
            }
            
            self.session.commitConfiguration()
            
            self.camera.addObserver(self, forKeyPath: "lensPosition", options: .New, context: &self.CONTEXT_LENS_LENGTH)
            self.camera.addObserver(self, forKeyPath: "ISO", options: .New, context: &self.CONTEXT_ISO)
            self.camera.addObserver(self, forKeyPath: "exposureDuration", options: .New, context: &self.CONTEXT_EXPOSURE_DURATION)
            self.session.startRunning()
            
            self.setupCamera(self.camera)
        }
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
        
        if camera.smoothAutoFocusSupported
        {
            camera.smoothAutoFocusEnabled = true
        }
        
        camera.unlockForConfiguration()
        
        focusWithMode(.ContinuousAutoFocus, exposureMode: .ContinuousAutoExposure, pointOfInterest: CGPoint(x: 0.5, y: 0.5))
    }
    
    @IBAction func screenTapped(sender: UITapGestureRecognizer)
    {
        print("tap")
        
        var point = sender.locationInView(sender.view)
        point = (previewView.layer as! AVCaptureVideoPreviewLayer).captureDevicePointOfInterestForPoint(point)
        focusWithMode(.ContinuousAutoFocus, exposureMode: .ContinuousAutoExposure, pointOfInterest: point)
    }
    
    func focusWithMode(focusMode:AVCaptureFocusMode, exposureMode:AVCaptureExposureMode, pointOfInterest:CGPoint)
    {
        let camera = self.camera
        dispatch_async(self.sessionQueue)
        {
            do
            {
                try camera.lockForConfiguration()
            }
            catch
            {
                return
            }
            
            if camera.focusPointOfInterestSupported
            {
                camera.focusPointOfInterest = pointOfInterest
            }
            
            if camera.isFocusModeSupported(focusMode)
            {
                camera.focusMode = focusMode
            }
            
            if camera.exposurePointOfInterestSupported
            {
                camera.exposurePointOfInterest = pointOfInterest
            }
            
            if camera.isExposureModeSupported(exposureMode)
            {
                camera.exposureMode = exposureMode
            }
            
            camera.subjectAreaChangeMonitoringEnabled = true
            camera.unlockForConfiguration()
        }
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>)
    {
        if context == &CONTEXT_LENS_LENGTH
        {
//            print("lensPosition", camera.lensPosition)
        }
        else
        if context == &CONTEXT_EXPOSURE_DURATION
        {
//            print("exposureDuration", camera.exposureDuration)
        }
        else
        if context == &CONTEXT_ISO
        {
//            print("ISO", camera.ISO)
        }
        else
        if context == &CONTEXT_OUTPUT_VOLUME
        {
            if let newVolume = change?[NSKeyValueChangeNewKey] as? Float,
                oldVolume = change?[NSKeyValueChangeOldKey] as? Float where newVolume > oldVolume
            {
                snapCamera()
            }
            
            if AVAudioSession.sharedInstance().outputVolume == 1.0
            {
                changeVolume(1.0 - 1.0 / 16.0)
            }
        }
    }
    
    func snapCamera()
    {
        print("snapCamera")
        dispatch_async(self.sessionQueue)
        {
            let imageConnection = self.imageOutput.connectionWithMediaType(AVMediaTypeVideo)
            imageConnection.videoOrientation = (self.previewView.layer as! AVCaptureVideoPreviewLayer).connection.videoOrientation
            
            self.imageOutput.captureStillImageAsynchronouslyFromConnection(imageConnection)
            { (buffer:CMSampleBuffer!, error:NSError!) in
                if error != nil
                {
                    self.showAlertMessage(String(format: "Error capture still image %@", error))
                }
                else
                if buffer != nil
                {
                    let data = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(buffer)
                    PHPhotoLibrary.requestAuthorization
                    { (status:PHAuthorizationStatus) in
                        if status == PHAuthorizationStatus.Authorized
                        {
                            let photoWriting = {
                                PHAssetCreationRequest.creationRequestForAsset().addResourceWithType(.Photo, data: data, options: nil)
                            }
                            
                            PHPhotoLibrary.sharedPhotoLibrary().performChanges(photoWriting)
                            { (success, error:NSError?) in
                                if !success
                                {
                                    self.showAlertMessage("Error occured while saving image to photo library")
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    //MARK: alert
    func showAlertMessage(message:String)
    {
        let alert = UIAlertController(title: "ERROR", message: message, preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "I've got it!", style: .Default, handler: nil))
        dispatch_async(dispatch_get_main_queue())
        {
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    //MARK: orientation
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator)
    {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        
        let deviceOrientation = UIDevice.currentDevice().orientation
        if deviceOrientation.isPortrait || deviceOrientation.isLandscape
        {
            (previewView.layer as! AVCaptureVideoPreviewLayer).connection.videoOrientation = AVCaptureVideoOrientation(rawValue: deviceOrientation.rawValue)!
        }
    }

    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
    }
}

