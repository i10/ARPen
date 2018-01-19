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

class ARManager: NSObject, ARSessionDelegate, ARSessionObserver, OpenCVWrapperDelegate {
    
    var scene: PenScene
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
    }
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        self.opencvWrapper.findMarker(frame.capturedImage)
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
    
    func markerTranslation(_ translation: [NSValue]!, rotation: [NSValue]!, ids: [NSNumber]!) {
        let positions = translation.map({$0.scnVector3Value})
        let eulerAngles = rotation.map({$0.scnVector3Value})
        let ids = ids.map({$0.intValue})
        
        for (position, (eulerAngle, id)) in zip(positions, zip(eulerAngles, ids)) {
            //self.scene.markerBox.setPosition(position, rotation: eulerAngle, forId: Int32(id))
            self.scene.markerBox.set(position: position, rotation: eulerAngle, forID: id)
        }
        //self.scene.pencilPoint.position = self.scene.markerBox.position(withIds: UnsafeMutablePointer(mutating: ids), count: Int32(ids.count))
        self.scene.pencilPoint.position = self.scene.markerBox.posititonWith(ids: ids)
        
        self.delegate?.finishedCalculation()
        
        self.scene.previousPoint = self.scene.pencilPoint.position
        
    }
    
    func noMarkerFound() {
        self.scene.previousPoint = nil
    }
    
}
