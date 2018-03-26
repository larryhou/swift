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
    private var FocusContext:String?
    private var ExposureContext:String?
    private var LensContext:String?
    
    @IBOutlet weak var torchSwitcher: UISwitch!
    @IBOutlet weak var previewView: CameraPreviewView!
    @IBOutlet weak var metadataView: CameraMetadataView!
    
    private var session:AVCaptureSession!
    private var activeCamera:AVCaptureDevice?

    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        session = AVCaptureSession()
        session.sessionPreset = .photo
        previewView.session = session
        (previewView.layer as! AVCaptureVideoPreviewLayer).videoGravity = .resizeAspectFill
        
        AVCaptureDevice.requestAccess(for: .video)
        { (success:Bool) -> Void in
            let status = AVCaptureDevice.authorizationStatus(for: .video)
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
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        if let resultController = presentedViewController as? ResultViewController
        {
            resultController.animate(visible: false)
        }
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        torchSwitcher.isHidden = true
        if !session.isRunning
        {
            session.startRunning()
        }
    }
    
    func applicationWillEnterForeground()
    {
        metadataView.setMetadataObjects([])
    }
    
    func findCamera(position:AVCaptureDevice.Position)->AVCaptureDevice!
    {
        let list = AVCaptureDevice.devices()
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
        
        guard let camera = findCamera(position: .back) else {return}
        self.activeCamera = camera
        
        do
        {
            let cameraInput = try AVCaptureDeviceInput(device: camera)
            if session.canAddInput(cameraInput)
            {
                session.addInput(cameraInput)
            }
            
            setupCamera(camera: camera)
        }
        catch {}
        
        let metadata = AVCaptureMetadataOutput()
        if session.canAddOutput(metadata)
        {
            session.addOutput(metadata)
            metadata.setMetadataObjectsDelegate(self, queue: .main)
            
            var metadataTypes = metadata.availableMetadataObjectTypes
            for i in 0..<metadataTypes.count
            {
                if metadataTypes[i] == .face
                {
                    metadataTypes.remove(at: i)
                    break
                }
            }
            
            metadata.metadataObjectTypes = metadataTypes
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
        
        if camera.isFocusModeSupported(.continuousAutoFocus)
        {
            camera.focusMode = .continuousAutoFocus
        }
        
        if camera.isAutoFocusRangeRestrictionSupported
        {
//            camera.autoFocusRangeRestriction = .near
        }
        
        if camera.isSmoothAutoFocusSupported
        {
            camera.isSmoothAutoFocusEnabled = true
        }
        
        camera.unlockForConfiguration()
        
//        camera.addObserver(self, forKeyPath: "adjustingFocus", options: .new, context: &FocusContext)
//        camera.addObserver(self, forKeyPath: "exposureDuration", options: .new, context: &ExposureContext)
        camera.addObserver(self, forKeyPath: "lensPosition", options: .new, context: &LensContext)
    }
    
    @IBAction func torchStatusChange(_ sender: UISwitch)
    {
        guard let camera = self.activeCamera else { return }
        guard camera.isTorchAvailable else {return}
        
        do { try camera.lockForConfiguration() } catch { return }
        
        if sender.isOn
        {
            if camera.isTorchModeSupported(.on)
            {
                try? camera.setTorchModeOn(level: AVCaptureDevice.maxAvailableTorchLevel)
            }
        }
        else
        {
            if camera.isTorchModeSupported(.off)
            {
                camera.torchMode = .off
            }
            
            checkTorchSwitcher(for: camera)
        }
        
        camera.unlockForConfiguration()
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?)
    {
        if context == &FocusContext || context == &ExposureContext || context == &LensContext, let camera = object as? AVCaptureDevice
        {
            print(camera.exposureDuration.seconds, camera.activeFormat.minExposureDuration.seconds, camera.activeFormat.maxExposureDuration.seconds,camera.iso, camera.lensPosition)
            checkTorchSwitcher(for: camera)
        }
    }
    
    func checkTorchSwitcher(`for` camera:AVCaptureDevice)
    {
        if camera.iso >= 400
        {
            torchSwitcher.isHidden = false;
        }
        else
        {
            torchSwitcher.isHidden = !camera.isTorchActive
        }
    }
    
    //MARK: metadataObjects processing
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection)
    {
        var codes:[AVMetadataMachineReadableCodeObject] = []
        var faces:[AVMetadataFaceObject] = []
        
        let layer = previewView.layer as! AVCaptureVideoPreviewLayer
        for item in metadataObjects
        {
            guard let mrc = layer.transformedMetadataObject(for: item) else {continue}
            switch mrc
            {
                case is AVMetadataMachineReadableCodeObject:
                    codes.append(mrc as! AVMetadataMachineReadableCodeObject)
                
                case is AVMetadataFaceObject:
                    faces.append(mrc as! AVMetadataFaceObject)
                
                default:
                    print(mrc)
            }
        }
        DispatchQueue.main.async
        {
            self.metadataView.setMetadataObjects(codes)
            self.showMetadataObjects(self.metadataView.mrcObjects)
        }
    }
    
    func showMetadataObjects(_ objects:[AVMetadataMachineReadableCodeObject])
    {
        if let resultController = self.presentedViewController as? ResultViewController
        {
            resultController.mrcObjects = objects
            resultController.reload()
            
            resultController.animate(visible: true)
        }
        else
        {
            guard let resultController = storyboard?.instantiateViewController(withIdentifier: "ResultViewController") as? ResultViewController else
            {
                return
            }
            resultController.mrcObjects = objects
            resultController.view.frame = view.frame
            present(resultController, animated: false, completion: nil)
        }
        
    }
    
    //MARK: orientation
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator)
    {
        super.viewWillTransition(to: size, with: coordinator)
        let orientation = UIDevice.current.orientation
        if orientation.isLandscape || orientation.isPortrait
        {
            let layer = previewView.layer as! AVCaptureVideoPreviewLayer
            if layer.connection != nil
            {
                layer.connection?.videoOrientation = AVCaptureVideoOrientation(rawValue: orientation.rawValue)!
            }
        }
        
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { return .all }
    
    override var prefersStatusBarHidden: Bool { return true }

    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
    }

}

