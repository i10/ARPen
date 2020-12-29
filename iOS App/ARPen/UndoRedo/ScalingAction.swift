//
//  ScalingAction.swift
//  ARPen
//
//  Created by Andreas RF Dymek on 29.12.20.
//  Copyright © 2020 RWTH Aachen. All rights reserved.
//

import Foundation

public class ScalingAction : Action {
    
    var diffInScale: SCNVector3
    
    init(occtRef: OCCTReference, scene: PenScene, diffInScale: SCNVector3) {
        self.diffInScale = diffInScale
        super.init(occtRef: occtRef, scene: scene)
    }
    
    override func undo() {
        let nodes = self.inScene.drawingNode.childNodes
       
        for node in nodes {
            let geomNode = node as? ARPGeomNode
            
            if geomNode?.occtReference == self.occtRef {
                geomNode!.scale -= diffInScale
                geomNode!.applyTransform()
            }
        }
        
    }
    
    override func redo() {
        let nodes = self.inScene.drawingNode.childNodes as? [ARPGeomNode]
       
        for node in nodes! {
            if node.occtReference == self.occtRef {
                node.scale += diffInScale
                node.applyTransform()
            }
        }
    }
    
}
