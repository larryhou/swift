/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Main view controller for the AR experience.
*/

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate
{
	// MARK: - IBOutlets

    @IBOutlet weak var sessionInfoView: UIView!
	@IBOutlet weak var sessionInfoLabel: UILabel!
	@IBOutlet weak var sceneView: ARSCNView!

	// MARK: - View Life Cycle
	
    /// - Tag: StartARSession
    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)

        guard ARWorldTrackingConfiguration.isSupported else
        {
            fatalError("""
                ARKit is not available on this device. For apps that require ARKit
                for core functionality, use the `arkit` key in the key in the
                `UIRequiredDeviceCapabilities` section of the Info.plist to prevent
                the app from installing. (If the app can't be installed, this error
                can't be triggered in a production scenario.)
                In apps where AR is an additive feature, use `isSupported` to
                determine whether to show UI for launching AR experiences.
            """) // For details, see https://developer.apple.com/documentation/arkit
        }

        /*
         Start the view's AR session with a configuration that uses the rear camera,
         device position and orientation tracking, and plane detection.
        */
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        sceneView.session.run(configuration)

        // Set a delegate to track the number of plane anchors for providing UI feedback.
        sceneView.session.delegate = self
        
        /*
         Prevent the screen from being dimmed after a while as users will likely
         have long periods of interaction without touching the screen or buttons.
        */
        UIApplication.shared.isIdleTimerDisabled = true
        
        // Show debug UI to view performance metrics (e.g. frames per second).
        sceneView.showsStatistics = true
    }
	
	override func viewWillDisappear(_ animated: Bool)
    {
		super.viewWillDisappear(animated)
		
		// Pause the view's AR session.
		sceneView.session.pause()
	}
	
	// MARK: - ARSCNViewDelegate
    
    /// - Tag: PlaceARContent
	func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor)
    {
        // Place content only for anchors found by plane detection.
        guard let anchor = anchor as? ARPlaneAnchor else { return }

        // Create a SceneKit plane to visualize the plane anchor using its position and extent.
        let plane = SCNPlane(width: CGFloat(anchor.extent.x), height: CGFloat(anchor.extent.z))
        plane.firstMaterial?.diffuse.contents = UIColor.green
        
        let sphere = SCNSphere(radius: CGFloat(min(anchor.extent.x,anchor.extent.z)) / 2)
        sphere.firstMaterial?.diffuse.contents = UIImage(named: "earth")
        sphere.segmentCount *= 4
        
        let planeNode = SCNNode(geometry: plane)
        planeNode.simdPosition = float3(anchor.center.x, 0, anchor.center.z)
        
        let sphereNode = SCNNode(geometry: sphere)
        sphereNode.simdPosition = float3(anchor.center.x, anchor.center.y, anchor.center.z)
        
        /*
         `SCNPlane` is vertically oriented in its local coordinate space, so
         rotate the plane to match the horizontal orientation of `ARPlaneAnchor`.
        */
        planeNode.runAction(.group([SCNAction.rotateTo(x: -.pi/2, y: 0, z: 0, duration: 3),
                                    SCNAction.fadeOpacity(to: 0.15, duration: 1)]))
        sphereNode.runAction(.rotateTo(x: 0, y: -.pi*2/3, z: 0, duration: 2))
        
        /*
         Add the plane visualization to the ARKit-managed node so that it tracks
         changes in the plane anchor as plane estimation continues.
        */
        node.addChildNode(planeNode)
        node.addChildNode(sphereNode)
	}
    
    let ROTATE_KEY = "rotate"

    /// - Tag: UpdateARContent
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor)
    {
        // Update content only for plane anchors and nodes matching the setup created in `renderer(_:didAdd:for:)`.
        guard let anchor = anchor as?  ARPlaneAnchor,
            let planeNode = node.childNodes.first,
            let plane = planeNode.geometry as? SCNPlane
            else { return }
        
        let sphere = node.childNodes[1]
        print(sphere.position, anchor.extent)
        
        // Plane estimation may shift the center of a plane relative to its anchor's transform.
        planeNode.simdPosition = float3(anchor.center.x, 0, anchor.center.z)
        sphere.simdPosition = float3(anchor.center.x, 0, anchor.center.z)
//        let rotate = SCNAction.move(to: SCNVector3(anchor.center.x, anchor.center.y, anchor.center.z), duration: 0.5)
//        sphere.runAction(rotate)
//        sphere.removeAction(forKey: ROTATE_KEY)
//        sphere.runAction(rotate, forKey: ROTATE_KEY)
//        planeNode.removeAction(forKey: ROTATE_KEY)
//        planeNode.runAction(rotate, forKey: ROTATE_KEY)
        
        /*
         Plane estimation may extend the size of the plane, or combine previously detected
         planes into a larger one. In the latter case, `ARSCNView` automatically deletes the
         corresponding node for one plane, then calls this method to update the size of
         the remaining plane.
        */
        plane.width = CGFloat(anchor.extent.x)
        plane.height = CGFloat(anchor.extent.z)
    }

    // MARK: - ARSessionDelegate

    func session(_ session: ARSession, didAdd anchors: [ARAnchor])
    {
        guard let frame = session.currentFrame else { return }
        updateSessionInfoLabel(for: frame, trackingState: frame.camera.trackingState)
    }

    func session(_ session: ARSession, didRemove anchors: [ARAnchor])
    {
        guard let frame = session.currentFrame else { return }
        updateSessionInfoLabel(for: frame, trackingState: frame.camera.trackingState)
    }

    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera)
    {
        updateSessionInfoLabel(for: session.currentFrame!, trackingState: camera.trackingState)
    }

    // MARK: - ARSessionObserver
	
	func sessionWasInterrupted(_ session: ARSession)
    {
		// Inform the user that the session has been interrupted, for example, by presenting an overlay.
		sessionInfoLabel.text = "Session was interrupted"
	}
	
	func sessionInterruptionEnded(_ session: ARSession)
    {
		// Reset tracking and/or remove existing anchors if consistent tracking is required.
		sessionInfoLabel.text = "Session interruption ended"
		resetTracking()
	}
    
    func session(_ session: ARSession, didFailWithError error: Error)
    {
        // Present an error message to the user.
        sessionInfoLabel.text = "Session failed: \(error.localizedDescription)"
        resetTracking()
    }

    // MARK: - Private methods

    private func updateSessionInfoLabel(for frame: ARFrame, trackingState: ARCamera.TrackingState)
    {
        // Update the UI to provide feedback on the state of the AR experience.
        let message: String

        switch trackingState
        {
            case .normal where frame.anchors.isEmpty:
                // No planes detected; provide instructions for this app's AR interactions.
                message = "Move the device around to detect horizontal surfaces."
            
            case .normal:
                // No feedback needed when tracking is normal and planes are visible.
                message = ""
            
            case .notAvailable:
                message = "Tracking unavailable."
            
            case .limited(.excessiveMotion):
                message = "Tracking limited - Move the device more slowly."
            
            case .limited(.insufficientFeatures):
                message = "Tracking limited - Point the device at an area with visible surface detail, or improve lighting conditions."
            
            case .limited(.initializing):
                message = "Initializing AR session."
            
        }

        sessionInfoLabel.text = message
        sessionInfoView.isHidden = message.isEmpty
    }

    private func resetTracking()
    {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
}
