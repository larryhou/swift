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

class CaptureViewController: UIViewController, AVCaptureFileOutputRecordingDelegate {
    var CONTEXT_LENS_LENGTH: Int = 0
    var CONTEXT_ISO: Int = 0
    var CONTEXT_EXPOSURE_DURATION: Int = 0
    var CONTEXT_OUTPUT_VOLUME: Int = 0
    var CONTEXT_MOVIE_RECORDING: Int = 0
    var CONTEXT_SESSION_RUNNING: Int = 0
    var CONTEXT_LIGHT_BOOST: Int = 0
    var CONTEXT_ADJUSTING_FOCUS: Int = 0

    @IBOutlet var previewView: LivePreivewView!
    @IBOutlet var flashView: UIView!

    @IBOutlet weak var recordingView: UIView!
    @IBOutlet weak var recordingMeter: UILabel!
    @IBOutlet weak var recordingIndicator: UIImageView!
    @IBOutlet weak var isoMeter: UILabel!
    @IBOutlet weak var focusIndicator: UIImageView!

    private var session: AVCaptureSession!
    private var sessionQueue: dispatch_queue_t!

    private var camera: AVCaptureDevice!

    private var photoOutput: AVCaptureStillImageOutput!
    private var movieOutput: AVCaptureMovieFileOutput!

    private var backgroundRecordingID: UIBackgroundTaskIdentifier!

    private var originVolume: Float = 1.0
    private var restoring = false

    private var timestamp: NSDate!
    private var timer: NSTimer!

    private var changeVolume: Float->Void = {volume in}

    dynamic
    var recording = false

    class func deviceWithMediaType(mediaType: String, position: AVCaptureDevicePosition) -> AVCaptureDevice {
        let devices = AVCaptureDevice.devicesWithMediaType(mediaType) as! [AVCaptureDevice]
        var target = devices.first

        for item in devices {
            if item.position == position {
                target = item
                break
            }
        }

        return target!

    }

    func restoreVolume() {
        if originVolume != AVAudioSession.sharedInstance().outputVolume {
            restoring = true
            changeVolume(originVolume)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.blackColor()

        focusIndicator.hidden = true
        isoMeter.hidden = true

        recordingView.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
        recordingView.alpha = 0.0

        let volumeView = MPVolumeView(frame: CGRect(x: -100, y: 0, width: 10, height: 0))
        volumeView.sizeToFit()

        view.addSubview(volumeView)

        for view in volumeView.subviews {
            if view.dynamicType.description() == "MPVolumeSlider" {
                let slider = view as! UISlider
                changeVolume = { value in
                    dispatch_async(dispatch_get_main_queue()) {
                        slider.setValue(value, animated: true)
                        slider.sendActionsForControlEvents(.TouchUpInside)
                    }
                }
                break
            }
        }

        addObserver(self, forKeyPath: "recording", options: .New, context: &CONTEXT_MOVIE_RECORDING)

        AVAudioSession.sharedInstance().addObserver(self, forKeyPath: "outputVolume", options: [.New, .Old], context: &CONTEXT_OUTPUT_VOLUME)
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        originVolume = AVAudioSession.sharedInstance().outputVolume

        session = AVCaptureSession()
        session.addObserver(self, forKeyPath: "running", options: .New, context: &CONTEXT_SESSION_RUNNING)
        session.sessionPreset = AVCaptureSessionPresetPhoto

        previewView.session = session

        sessionQueue = dispatch_queue_create("CaptureSessionQueue", DISPATCH_QUEUE_SERIAL)

        var authorized = true
        let status = AVCaptureDevice.authorizationStatusForMediaType(AVMediaTypeVideo)
        switch status {
            case .NotDetermined, .Denied:
                dispatch_suspend(self.sessionQueue)
                AVCaptureDevice.requestAccessForMediaType(AVMediaTypeVideo) { (granted: Bool) in

                    if !granted {
                        authorized = false
                    }

                    dispatch_resume(self.sessionQueue)
                }
            default:
                print(status, status.rawValue)
        }

        dispatch_async(self.sessionQueue) {
            if !authorized {
                return
            }

            self.backgroundRecordingID = UIBackgroundTaskInvalid

            // MARK: camera input
            let cameraDevice = CaptureViewController.deviceWithMediaType(AVMediaTypeVideo, position: .Back)
            var cameraInput: AVCaptureDeviceInput! = nil

            do {
                cameraInput = try AVCaptureDeviceInput(device: cameraDevice)
            } catch {
                self.showAlertMessage(String(error))
                return
            }

            self.camera = cameraDevice
            self.session.beginConfiguration()

            if self.session.canAddInput(cameraInput) {
                self.session.addInput(cameraInput)

                dispatch_async(dispatch_get_main_queue()) {
                    var vedioOrientation = AVCaptureVideoOrientation.Portrait

                    let deviceOrientation = UIApplication.sharedApplication().statusBarOrientation
                    if deviceOrientation != .Unknown {
                        vedioOrientation = AVCaptureVideoOrientation(rawValue: deviceOrientation.rawValue)!
                    }

                    (self.previewView.layer as! AVCaptureVideoPreviewLayer).connection.videoOrientation = vedioOrientation
                }
            } else {
                self.showAlertMessage("Could not add camera input")
                return
            }

            // MARK: microphone input
            let audio = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeAudio)
            var audioInput: AVCaptureDeviceInput! = nil
            do {
                audioInput = try AVCaptureDeviceInput(device: audio)
            } catch {}

            if audioInput != nil && self.session.canAddInput(audioInput) {
                self.session.addInput(audioInput)
            } else {
                self.showAlertMessage("Could not add microphone input")
            }

            // MARK: photo output
            let photoOutput = AVCaptureStillImageOutput()
            if self.session.canAddOutput(photoOutput) {
                self.session.addOutput(photoOutput)
                self.photoOutput = photoOutput
                photoOutput.outputSettings = [AVVideoCodecKey: AVVideoCodecJPEG]
                photoOutput.highResolutionStillImageOutputEnabled = true
            } else {
                self.showAlertMessage("Could not add photo output")
            }

            // MARK: movie output
            let movieOutput = AVCaptureMovieFileOutput()
            if self.session.canAddOutput(movieOutput) {
                self.session.addOutput(movieOutput)
                self.movieOutput = movieOutput

                let movieConnnection = movieOutput.connectionWithMediaType(AVMediaTypeVideo)
                if  movieConnnection.supportsVideoStabilization {
                    movieConnnection.preferredVideoStabilizationMode = .Auto
                }
            } else {
                self.showAlertMessage("Could not add movie output")
            }

            self.session.commitConfiguration()

            self.camera.addObserver(self, forKeyPath: "lensPosition", options: .New, context: &self.CONTEXT_LENS_LENGTH)
            self.camera.addObserver(self, forKeyPath: "ISO", options: .New, context: &self.CONTEXT_ISO)
            self.camera.addObserver(self, forKeyPath: "exposureDuration", options: .New, context: &self.CONTEXT_EXPOSURE_DURATION)
            self.camera.addObserver(self, forKeyPath: "lowLightBoostEnabled", options: .New, context: &self.CONTEXT_LIGHT_BOOST)
            self.camera.addObserver(self, forKeyPath: "adjustingFocus", options: .New, context: &self.CONTEXT_ADJUSTING_FOCUS)
            self.session.startRunning()
        }
    }

    func setupCamera(device: AVCaptureDevice) {
        do {
            try device.lockForConfiguration()
        } catch {
            return
        }

        if device.smoothAutoFocusSupported {
            device.smoothAutoFocusEnabled = true
        }

        if device.lowLightBoostSupported {
            device.automaticallyEnablesLowLightBoostWhenAvailable = true
        }

        device.unlockForConfiguration()

        focusWithMode(.ContinuousAutoFocus, exposureMode: .ContinuousAutoExposure, pointOfInterest: CGPoint(x: 0.5, y: 0.5))
    }

    @IBAction func screenTapped(sender: UITapGestureRecognizer) {
        print("tap")

        var point = sender.locationInView(sender.view)
        point = (previewView.layer as! AVCaptureVideoPreviewLayer).captureDevicePointOfInterestForPoint(point)
        focusWithMode(.ContinuousAutoFocus, exposureMode: .ContinuousAutoExposure, pointOfInterest: point)
    }

    func focusWithMode(focusMode: AVCaptureFocusMode, exposureMode: AVCaptureExposureMode, pointOfInterest: CGPoint) {
        let camera = self.camera
        dispatch_async(self.sessionQueue) {
            do {
                try camera.lockForConfiguration()
            } catch {
                return
            }

            if camera.focusPointOfInterestSupported {
                camera.focusPointOfInterest = pointOfInterest
            }

            if camera.isFocusModeSupported(focusMode) {
                camera.focusMode = focusMode
            }

            if camera.exposurePointOfInterestSupported {
                camera.exposurePointOfInterest = pointOfInterest
            }

            if camera.isExposureModeSupported(exposureMode) {
                camera.exposureMode = exposureMode
            }

            camera.subjectAreaChangeMonitoringEnabled = true
            camera.unlockForConfiguration()
        }
    }

    var snapIndex = 0
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String: AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if context == &CONTEXT_LENS_LENGTH {
//            print("lensPosition", camera.lensPosition)
        } else
        if context == &CONTEXT_EXPOSURE_DURATION {
//            print("exposureDuration", camera.exposureDuration)
        } else
        if context == &CONTEXT_ISO {
            isoMeter.text = String(format: "ISO:%04d", Int(camera.ISO))
        } else
        if context == &CONTEXT_OUTPUT_VOLUME {
            let newVolume = change?[NSKeyValueChangeNewKey] as! Float
            let oldVolume = change?[NSKeyValueChangeOldKey] as! Float
            if abs(newVolume - oldVolume) == 0.5 || !session.running {
                return
            }

            if restoring {
                restoring = false
                return
            }

            ++snapIndex
            print("snap", String(format: "%03d %@ %.3f %.3f", snapIndex, newVolume > oldVolume ? "+" : "-", newVolume, oldVolume))

            if newVolume > oldVolume {
                snapCamera()
            } else {
                recording = !recording
            }

            checkVolumeButton()
        } else
        if context == &CONTEXT_MOVIE_RECORDING {
            toggleRecording()
        } else
        if context == &CONTEXT_SESSION_RUNNING {
            print("running", session.running)

            if session.running {
                setupCamera(camera)
                checkVolumeButton()
            }
        } else
        if context == &CONTEXT_LIGHT_BOOST {
            print("lowLightBoostEnabled", camera.lowLightBoostEnabled)
        } else
        if context == &CONTEXT_ADJUSTING_FOCUS {
            focusIndicator.hidden = !camera.adjustingFocus
            if camera.adjustingFocus {
                focusIndex = 0
                NSTimer.scheduledTimerWithTimeInterval(0.15, target: self, selector: "twinkleFocusBox:", userInfo: nil, repeats: true)
            }
        }
    }

    var focusIndex = 0
    func twinkleFocusBox(timer: NSTimer) {
        if !camera.adjustingFocus {
            timer.invalidate()
            return
        }

        focusIndex++

        let alpha: CGFloat
        if focusIndex % 2 == 1 {
            alpha = 1.0
        } else {
            alpha = 0.5
        }

        focusIndicator.layer.removeAllAnimations()
        UIView.animateWithDuration(0.1) {
            self.focusIndicator.alpha = alpha
        }
    }

    func updateRecordingMeter(interval: NSTimeInterval) {
        let time = Int(interval)

        let sec = time % 60
        let min = (time / 60) % 60
        let hur = (time / 60) / 60

        recordingMeter.text = String(format: "%02d:%02d:%02d", hur, min, sec)
    }

    func timerUpdate(timer: NSTimer) {
        updateRecordingMeter(timer.fireDate.timeIntervalSinceDate(timestamp))
        recordingIndicator.hidden = !recordingIndicator.hidden
    }

    func toggleRecording() {
        dispatch_async(sessionQueue) {
            if !self.movieOutput.recording {
                print("recording", true)
                self.session.sessionPreset = AVCaptureSessionPresetHigh

                if UIDevice.currentDevice().multitaskingSupported {
                    self.backgroundRecordingID = UIApplication.sharedApplication().beginBackgroundTaskWithExpirationHandler(nil)
                }

                let movieConnection = self.movieOutput.connectionWithMediaType(AVMediaTypeVideo)
                movieConnection.videoOrientation = (self.view.layer as! AVCaptureVideoPreviewLayer).connection.videoOrientation

                let movieFileName = NSString(string: NSProcessInfo.processInfo().globallyUniqueString).stringByAppendingPathExtension("mov")!
                let movieFilePath = NSString(string: NSTemporaryDirectory()).stringByAppendingPathComponent(movieFileName)

                self.movieOutput.startRecordingToOutputFileURL(NSURL.fileURLWithPath(movieFilePath), recordingDelegate: self)
            } else {
                print("recording", false)
                self.movieOutput.stopRecording()
            }
        }
    }

    func twenkleScreen() {
        flashView.layer.removeAllAnimations()
        flashView.hidden = false
        flashView.alpha = 1.0

        let animations = {
            self.flashView.alpha = 0.0
        }

        UIView.animateWithDuration(0.2, animations: animations) { _ in
            self.flashView.hidden = true
        }
    }

    // MARK: take still image
    func snapCamera() {
        twenkleScreen()
        dispatch_async(self.sessionQueue) {
            let imageConnection = self.photoOutput.connectionWithMediaType(AVMediaTypeVideo)
            imageConnection.videoOrientation = (self.previewView.layer as! AVCaptureVideoPreviewLayer).connection.videoOrientation

            self.photoOutput.captureStillImageAsynchronouslyFromConnection(imageConnection) { (buffer: CMSampleBuffer!, error: NSError!) in
                if error != nil {
                    self.showAlertMessage(String(format: "Error capture still image %@", error))
                } else
                if buffer != nil {
                    let data = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(buffer)
                    PHPhotoLibrary.requestAuthorization { (status: PHAuthorizationStatus) in
                        if status == PHAuthorizationStatus.Authorized {
                            let photoWriting = {
                                PHAssetCreationRequest.creationRequestForAsset().addResourceWithType(.Photo, data: data, options: nil)
                            }

                            PHPhotoLibrary.sharedPhotoLibrary().performChanges(photoWriting) { (success, _: NSError?) in
                                if !success {
                                    self.showAlertMessage("Error occured while saving image to photo library")
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: check volume button
    func checkVolumeButton() {
        do {
            try AVAudioSession.sharedInstance().setActive(true, withOptions: .NotifyOthersOnDeactivation)
        } catch {}

        let volume = AVAudioSession.sharedInstance().outputVolume
        if volume == 1.0 || volume == 0.0 {
            changeVolume(0.5)
        }
    }

    // MARK: record delegate
    func captureOutput(captureOutput: AVCaptureFileOutput!, didStartRecordingToOutputFileAtURL fileURL: NSURL!, fromConnections connections: [AnyObject]!) {
        print(__FUNCTION__)

        dispatch_async(dispatch_get_main_queue()) {
            self.recordingView.layer.removeAllAnimations()
            self.recordingView.alpha = 0.5

            UIView.animateWithDuration(0.2) {
                self.recordingView.alpha = 1.0
            }

            self.timestamp = NSDate()

            self.updateRecordingMeter(0)
            self.timer = NSTimer.scheduledTimerWithTimeInterval(0.5, target: self, selector: "timerUpdate:", userInfo: nil, repeats: true)
        }
    }

    func captureOutput(captureOutput: AVCaptureFileOutput!, didFinishRecordingToOutputFileAtURL outputFileURL: NSURL!, fromConnections connections: [AnyObject]!, error: NSError!) {
        print(__FUNCTION__)

        timer.invalidate()
        dispatch_async(dispatch_get_main_queue()) {
            self.recordingView.layer.removeAllAnimations()
            UIView.animateWithDuration(0.5) {
                self.recordingView.alpha = 0.0
            }
        }

        session.sessionPreset = AVCaptureSessionPresetPhoto
        checkVolumeButton()

        // MARK: write movie file
        let backgroundTaskID = self.backgroundRecordingID
        self.backgroundRecordingID = UIBackgroundTaskInvalid

        let cleanup = {
            do {
                try NSFileManager.defaultManager().removeItemAtURL(outputFileURL)
            } catch {}

            if backgroundTaskID != UIBackgroundTaskInvalid {
                UIApplication.sharedApplication().endBackgroundTask(backgroundTaskID)
            }
        }

        var success = true
        if error != nil {
           success = error.userInfo[AVErrorRecordingSuccessfullyFinishedKey] as! Bool
        }

        if success {
            PHPhotoLibrary.requestAuthorization { (status: PHAuthorizationStatus) in
                if status == PHAuthorizationStatus.Authorized {
                    let movieWriting = {
                        let options = PHAssetResourceCreationOptions()
                        options.shouldMoveFile = true

                        let request = PHAssetCreationRequest.creationRequestForAsset()
                        request.addResourceWithType(.Video, fileURL: outputFileURL, options: options)
                    }

                    PHPhotoLibrary.sharedPhotoLibrary().performChanges(movieWriting) { (success: Bool, error: NSError?) in
                        if !success {
                            self.showAlertMessage(String(format: "Could not save movie to photo library: %@", error!))
                        }

                        cleanup()
                    }
                } else {
                    cleanup()
                }
            }
        } else {
            cleanup()
        }
    }

    // MARK: alert
    func showAlertMessage(message: String) {
        let alert = UIAlertController(title: "ERROR", message: message, preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "I've got it!", style: .Default, handler: nil))
        dispatch_async(dispatch_get_main_queue()) {
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }

    // MARK: orientation
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)

        let deviceOrientation = UIDevice.currentDevice().orientation
        if deviceOrientation.isPortrait || deviceOrientation.isLandscape {
            (previewView.layer as! AVCaptureVideoPreviewLayer).connection.videoOrientation = AVCaptureVideoOrientation(rawValue: deviceOrientation.rawValue)!
        }
    }

    override func prefersStatusBarHidden() -> Bool {
        return true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}
