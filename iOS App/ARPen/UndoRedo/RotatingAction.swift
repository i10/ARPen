//
//  RotatingAction.swift
//  ARPen
//
//  Created by Andreas RF Dymek on 29.12.20.
//  Copyright © 2020 RWTH Aachen. All rights reserved.
//

import Foundation

public class RotatingAction : Action {
    
    //private let diffInOrientation: simd_quatf
    
    private let diffInEuler: SCNVector3
    
    init(occtRef: OCCTReference, scene: PenScene, diffInEuler: SCNVector3){
        self.diffInEuler = diffInEuler
        super.init(occtRef: occtRef, scene: scene)
    }
    
    override func undo() {
        let nodes = self.inScene.drawingNode.childNodes
       
        for node in nodes {
            let geomNode = node as? ARPGeomNode
            
            if geomNode?.occtReference == self.occtRef {
                geomNode?.eulerAngles -= diffInEuler
                geomNode!.applyTransform()
                
            }
        }
        
    }
    
    override func redo() {
        let nodes = self.inScene.drawingNode.childNodes
       
        for node in nodes {
            let geomNode = node as? ARPGeomNode
            
            if geomNode?.occtReference == self.occtRef {
                geomNode?.eulerAngles += diffInEuler
                geomNode!.applyTransform()
            }
        }
    }
    
    
    
    
}
