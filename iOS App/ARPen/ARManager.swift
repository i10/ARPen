//
//  ARManager.swift
//  ARPen
//
//  Created by Felix Wehnert on 16.01.18.
//  Copyright © 2018 RWTH Aachen. All rights reserved.
//

import ARKit


protocol ARManagerDelegate {
    func didChangeTrackingState(cam: ARCamera)
    func finishedCalculation()
}

/**
 The ARManager is the the ARSessionDelegate, the ARSessionObserver and the OpenCVWrapperDelegate of ARPen
 It holds the openCVWrapper
 */
class ARManager: NSObject, ARSessionDelegate, ARSessionObserver, OpenCVWrapperDelegate {
    
    private(set) weak var scene: PenScene?
    var opencvWrapper: OpenCVWrapper
    var delegate: ARManagerDelegate?
    
    init(scene: PenScene) {
        self.scene = scene
        self.opencvWrapper = OpenCVWrapper()
        super.init()
        self.opencvWrapper.delegate = self
    }
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        self.delegate?.didChangeTrackingState(cam: camera)
        
        // create a dictionary literal to pass currentFrame and trackingState
        let informationPackage: [String : Any] = ["currentFrame": session.currentFrame!, "trackingState": camera.trackingState]
        NotificationCenter.default.post(name: .cameraDidChangeTrackingState, object: nil, userInfo: informationPackage)
    }
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        self.opencvWrapper.findMarker(frame.capturedImage, withCameraIntrinsics: frame.camera.intrinsics, cameraSize: frame.camera.imageResolution)
        
        // create a dictionary literal to pass frame and trackingState
        let informationPackage: [String : Any] = ["frame": frame, "trackingState": frame.camera.trackingState]
        NotificationCenter.default.post(name: .sessionDidUpdate, object: nil, userInfo: informationPackage)
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
    
    // MARK: - OpenCVWrapperDelegate
    /**
     Callback of the OpenCVWrapper
     */
    func markerTranslation(_ translation: [NSValue]!, rotation: [NSValue]!, ids: [NSNumber]!) {
        guard let scene = self.scene else {
            return
        }
        let positions = translation.map({$0.scnVector3Value})
        let eulerAngles = rotation.map({$0.scnVector3Value})
        let ids = ids.map { MarkerFace(rawValue: $0.intValue) ?? .notExpected }
        
        guard !ids.contains(.notExpected) else {
            fatalError("Marker IDs not recognized!")
        }
        
        
        for (position, (eulerAngle, id)) in zip(positions, zip(eulerAngles, ids)) {
            //self.scene.markerBox.setPosition(position, rotation: eulerAngle, forId: Int32(id))
            scene.markerBox.set(position: position, rotation: eulerAngle, forID: id)
        }
        scene.markerFound = true
        //self.scene.pencilPoint.position = self.scene.markerBox.position(withIds: UnsafeMutablePointer(mutating: ids), count: Int32(ids.count))
        let markerBoxNode = scene.markerBox.posititonWith(ids: ids)
        scene.pencilPoint.transform = markerBoxNode.transform
        
        
        self.delegate?.finishedCalculation()
    }
    
    /**
     Callback of OpenCVWrapper
     */
    func noMarkerFound() {
        guard let scene = self.scene else {
            return
        }
        scene.markerFound = false
        self.delegate?.finishedCalculation()
    }
    
}
