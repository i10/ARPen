//
//  CenterScalingAction.swift
//  ARPen
//
//  Created by Andreas RF Dymek on 10.01.21.
//  Copyright © 2021 RWTH Aachen. All rights reserved.
//

import Foundation

public class CenterScalingAction : Action {
    
    var diffInScale: SCNVector3
    var centerBefore: SCNVector3
    var pivotCentered: Bool
   
    
    init(occtRef: OCCTReference, scene: PenScene, diffInScale: SCNVector3, centerBefore: SCNVector3, pivotCentered: Bool) {
        self.diffInScale = diffInScale
        self.centerBefore = centerBefore
        self.pivotCentered = pivotCentered
        super.init(occtRef: occtRef, scene: scene)
    }
    
    override func undo() {
        let nodes = self.inScene.drawingNode.childNodes
       
        for node in nodes {
            let geomNode = node as? ARPGeomNode
            
            if geomNode?.occtReference == self.occtRef {
                
                if(!pivotCentered){
                    
                    geomNode?.scale -= diffInScale
                    
                    let centerAfter = geomNode?.convertPosition(geomNode!.geometryNode.boundingSphere.center, to: self.inScene.drawingNode)
                    
                    let diff = centerBefore - centerAfter!

                    geomNode?.position += diff
                    
                }
                
                else{
                    geomNode?.scale -= diffInScale
                }
                
                geomNode!.applyTransform()
            }
        }
        
    }
    
    override func redo() {
        let nodes = self.inScene.drawingNode.childNodes
       
        for node in nodes {
            let geomNode = node as? ARPGeomNode
            
            if geomNode?.occtReference == self.occtRef {
                
                if(!pivotCentered){
                    
                    geomNode?.scale += diffInScale
                    
                    let centerAfter = geomNode?.convertPosition(geomNode!.geometryNode.boundingSphere.center, to: self.inScene.drawingNode)
                    
                    let diff = centerBefore - centerAfter!

                    geomNode?.position += diff
                    
                }
                
                else{
                    geomNode?.scale += diffInScale
                }
                
                
                geomNode!.applyTransform()
            }
        }
    }
}
