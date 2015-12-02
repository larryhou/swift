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
    var CONTEXT_MOVIE_RECORDING:Int = 0
    var CONTEXT_SESSION_RUNNING:Int = 0
    
    @IBOutlet var previewView: LivePreivewView!
    @IBOutlet var flashView:UIView!
    
    @IBOutlet weak var recordingView: UIView!
    private var session:AVCaptureSession!
    private var sessionQueue:dispatch_queue_t!
    
    private var camera:AVCaptureDevice!
    private var cameraInput:AVCaptureDeviceInput!
    private var imageOutput:AVCaptureStillImageOutput!
    
    private var changeVolume:Float->Void = {volume in}
    
    dynamic
    var recording = false
    
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
        
        recordingView.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.3)
        
        let volumeView = MPVolumeView(frame: CGRect(x: -100, y: 0, width: 10, height: 0))
        volumeView.sizeToFit()
        
        view.addSubview(volumeView)
        
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
            try AVAudioSession.sharedInstance().setActive(true, withOptions: .NotifyOthersOnDeactivation)
        }
        catch {}
        
        changeVolume(0.5)
        AVAudioSession.sharedInstance().addObserver(self, forKeyPath: "outputVolume", options: [.New, .Old], context: &CONTEXT_OUTPUT_VOLUME)
        addObserver(self, forKeyPath: "recording", options: .New, context: &CONTEXT_MOVIE_RECORDING)
    }
    
    override func viewDidAppear(animated: Bool)
    {
        super.viewDidAppear(animated)
        
        session = AVCaptureSession()
        session.addObserver(self, forKeyPath: "running", options: .New, context: &CONTEXT_SESSION_RUNNING)
        
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
            let newVolume = change?[NSKeyValueChangeNewKey] as! Float
            let oldVolume = change?[NSKeyValueChangeOldKey] as! Float
            if abs(newVolume - oldVolume) == 0.5 || !session.running
            {
                return
            }
            
            ++snapEventIndex
            print("snap", String(format: "%03d %@ %.3f %.3f", snapEventIndex, newVolume > oldVolume ? "+" : "-", newVolume, oldVolume))
            
            if newVolume > oldVolume
            {
                twenkleScreen()
                snapCamera(snapEventIndex >= 0)
            }
            else
            {
                recording = !recording
            }
            
            if abs(AVAudioSession.sharedInstance().outputVolume - 0.5) == 0.5
            {
                changeVolume(0.5)
            }
        }
        else
        if context == &CONTEXT_MOVIE_RECORDING
        {
            print("recording", recording)
        }
        else
        if context == &CONTEXT_SESSION_RUNNING
        {
            print("running", session.running)
        }
    }
    
    var snapEventIndex = 0
    
    func twenkleScreen()
    {
        flashView.layer.removeAllAnimations()
        flashView.hidden = false
        flashView.alpha = 1.0
        
        let animations = {
            self.flashView.alpha = 0.0
        }
        
        UIView.animateWithDuration(0.2, animations:animations)
        { success in
            self.flashView.hidden = true
        }
    }
    
    func snapCamera(ignoreCurrentSnap:Bool = false)
    {
        if ignoreCurrentSnap
        {
            return
        }
        
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
    
    override func prefersStatusBarHidden() -> Bool
    {
        return true
    }

    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
    }
}

