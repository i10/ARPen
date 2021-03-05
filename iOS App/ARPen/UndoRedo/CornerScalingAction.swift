//
//  CornerScalingAction.swift
//  ARPen
//
//  Created by Andreas RF Dymek on 02.01.21.
//  Copyright © 2021 RWTH Aachen. All rights reserved.
//

import Foundation

public class CornerScalingAction : Action {
    
    var diffInScale: SCNVector3
    var diagonalNodeBefore: SCNNode
   
    
    init(occtRef: OCCTReference, scene: PenScene, diffInScale: SCNVector3, diagonalNodeBefore: SCNNode) {
        self.diffInScale = diffInScale
        self.diagonalNodeBefore = diagonalNodeBefore
        super.init(occtRef: occtRef, scene: scene)
    }
    
    override func undo() {
        let nodes = self.inScene.drawingNode.childNodes
       
        for node in nodes {
            let geomNode = node as? ARPGeomNode
            
            if geomNode?.occtReference == self.occtRef {
                cornerScaling(node: geomNode!, diagonalNodeBefore: self.diagonalNodeBefore, undo: true)
                geomNode!.applyTransform()
            }
        }
        
    }
    
    override func redo() {
        let nodes = self.inScene.drawingNode.childNodes
       
        for node in nodes {
            let geomNode = node as? ARPGeomNode
            
            if geomNode?.occtReference == self.occtRef {
                cornerScaling(node: geomNode!, diagonalNodeBefore: self.diagonalNodeBefore, undo: false)
                geomNode!.applyTransform()
            }
        }
    }
    
    
    //used to undo/redo the cornerScaling
    func cornerScaling(node: ARPGeomNode, diagonalNodeBefore: SCNNode, undo: Bool){
        
        let before = diagonalNodeBefore.position
        let name = diagonalNodeBefore.name
        
        if undo {
            node.scale -= diffInScale
        }
        
        //redo
        else{
            node.scale += diffInScale
        }
        
        let pitch = node.eulerAngles.x
        let yaw = node.eulerAngles.y
        let roll = node.eulerAngles.z
            
        node.eulerAngles = SCNVector3(0,0,0)
            
        //mincorner of bounding box
        let lbd = node.convertPosition(node.boundingBox.min, to: self.inScene.drawingNode)
                                   
        //maxcorner of bounding box
        let rfu = node.convertPosition(node.boundingBox.max, to: self.inScene.drawingNode)
     
        //Determine height and width of bounding box
        let height = rfu.y - lbd.y
        let width = rfu.x - lbd.x
        
        let rbd = lbd + SCNVector3(x: width, y: 0, z: 0)
        let lbu = lbd + SCNVector3(x: 0, y: height, z: 0)
        let rbu = lbu + SCNVector3(x: width, y: 0, z: 0)
        
        let rfd = rfu - SCNVector3(x: 0, y: height, z: 0)
        let lfu = rfu - SCNVector3(x: width, y: 0, z: 0)
        let lfd = lfu - SCNVector3(x: 0, y: height, z: 0)
       
        var corners: [String: SCNVector3] = ["lbd": lbd, "rbd": rbd, "lbu": lbu, "rbu": rbu, "lfd": lfd, "rfd": rfd, "lfu": lfu, "rfu": rfu]
        
        for (key , position) in corners {
            let tempPos = position - node.position
            let rotatedX = (cos(roll)*cos(yaw))*tempPos.x + (cos(roll)*sin(yaw)*sin(pitch)-sin(roll)*cos(pitch))*tempPos.y + (cos(roll)*sin(yaw)*cos(pitch)+sin(roll)*sin(pitch))*tempPos.z
            let rotatedY = (sin(roll)*cos(yaw))*tempPos.x + (sin(roll)*sin(yaw)*sin(pitch)+cos(roll)*cos(pitch))*tempPos.y + (sin(roll)*sin(yaw)*cos(pitch)-cos(roll)*sin(pitch))*tempPos.z
            let rotatedZ = (-sin(yaw))*tempPos.x + (cos(yaw)*sin(pitch))*tempPos.y + (cos(yaw)*cos(pitch))*tempPos.z
            corners[key] = SCNVector3(rotatedX + node.position.x, rotatedY + node.position.y, rotatedZ + node.position.z)
           
        }
        
        node.eulerAngles = SCNVector3(pitch,yaw,roll)
      
        let x_of_diff = before.x - corners[name!]!.x
        let y_of_diff = before.y - corners[name!]!.y
        let z_of_diff = before.z - corners[name!]!.z

        let diff = SCNVector3(x: x_of_diff, y: y_of_diff, z: z_of_diff)
            
        node.position += diff
        
    }
    
}
