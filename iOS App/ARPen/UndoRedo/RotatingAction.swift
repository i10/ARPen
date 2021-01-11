//
//  RotatingAction.swift
//  ARPen
//
//  Created by Andreas RF Dymek on 29.12.20.
//  Copyright © 2020 RWTH Aachen. All rights reserved.
//

import Foundation

public class RotatingAction : Action {
    
    //ewe save position before and after rotation to account for a non-centered pivot point. Should be the easiest approach
    var diffInEulerAngles: SCNVector3
    var previousPosition: SCNVector3
    var newPosition: SCNVector3

   
    init(occtRef: OCCTReference, scene: PenScene, diffInEulerAngles: SCNVector3, prevPos: SCNVector3, newPos: SCNVector3){
       
        self.diffInEulerAngles = diffInEulerAngles
        self.previousPosition = prevPos
        self.newPosition = newPos
        super.init(occtRef: occtRef, scene: scene)
    }
    
    override func undo() {
        let nodes = self.inScene.drawingNode.childNodes
       
        for node in nodes {
            let geomNode = node as? ARPGeomNode
            
            if geomNode?.occtReference == self.occtRef {
    
                geomNode?.eulerAngles -= diffInEulerAngles
                geomNode?.position = previousPosition
                geomNode!.applyTransform()
                
               
            }
        }
        
    }
    
    override func redo() {
        let nodes = self.inScene.drawingNode.childNodes
       
        for node in nodes {
            let geomNode = node as? ARPGeomNode
            
            if geomNode?.occtReference == self.occtRef {
                
                geomNode?.eulerAngles += diffInEulerAngles
                geomNode?.position = newPosition
                geomNode!.applyTransform()
                
            }
        }
    }
    
    
    
    
}
