//
//  PathAction.swift
//  ARPen
//
//  Created by Andreas RF Dymek on 29.12.20.
//  Copyright © 2020 RWTH Aachen. All rights reserved.
//

import Foundation

class PathAction : Action {
    
    var path: ARPPath
    
    init(scene: PenScene, path: ARPPath){
        self.path = path
        super.init(scene: scene)
    }

}



class PathFinishedAction : PathAction {
    
    var lastNode: ARPPathNode
    var originalPoints: [ARPPathNode]
    var originallyClosed: Bool
    var curveDesigner: CurveDesigner
        
    init(scene: PenScene, path: ARPPath, lastNode: ARPPathNode, originallyClosed: Bool, curveDesigner: CurveDesigner){
        self.originalPoints = path.points
        self.originallyClosed = originallyClosed
        self.lastNode = lastNode
        self.curveDesigner = curveDesigner
        super.init(scene: scene, path: path)
        
    }
    
    override func undo() {

        path.finished = false
        
        //profile
        if self.originallyClosed == true {
            path.closed = false
            path.removeLastPoint()
            curveDesigner.activePath = path
            path.appendPoint(lastNode)
            let newNode = ARPPathNode(inScene.pencilPoint.position, cornerStyle: lastNode.cornerStyle)
            path.appendPoint(newNode)
            
        }
       
        //path
        else {
            curveDesigner.activePath = path
            let newNode = ARPPathNode(inScene.pencilPoint.position, cornerStyle: lastNode.cornerStyle)
            path.appendPoint(newNode)
        }
        
        
        
        
    }
    
    override func redo() {
        
        path.finished = true
        
        //profile
        if self.originallyClosed == true {
            
            originalPoints.filter({ !$0.fixed }).forEach({ $0.removeFromParentNode() })
            originalPoints.removeAll(where: { !$0.fixed })
            
            curveDesigner.activePath = nil
            
            for _ in path.points {
                path.removeLastPoint()
            }
            
            path.rebuild()
            path.removeFromParentNode()
            
            for point in originalPoints {
                path.appendPoint(point)
            }
            
            path.closed = true
            path.removeNonFixedPoints()
            path.rebuild()
            
            inScene.drawingNode.addChildNode(path)
            
            path.runAction(ARPPath.finalizeAnimation)

        }
        
        else{
            
            originalPoints.filter({ !$0.fixed }).forEach({ $0.removeFromParentNode() })
            originalPoints.removeAll(where: { !$0.fixed })
            
            curveDesigner.activePath = nil
            
            for _ in path.points {
                path.removeLastPoint()
            }
            
            path.rebuild()
            path.removeFromParentNode()
            
            for point in originalPoints {
                path.appendPoint(point)
            }
            
            path.rebuild()
            
            inScene.drawingNode.addChildNode(path)
            
            path.runAction(ARPPath.finalizeAnimation)
        }
   
     
    }
}


class AddedNodeToPathAction: PathAction {

    var originalPoints: [ARPPathNode]
    var pathNode: ARPPathNode
    var curveDesigner: CurveDesigner
  
        
    init(scene: PenScene, path: ARPPath, node: ARPPathNode, curveDesigner: CurveDesigner){
        self.originalPoints = path.points
        self.pathNode = node
        self.curveDesigner = curveDesigner
        super.init(scene: scene, path: path)
    }
    
    override func undo() {
        path.removeNonFixedPoints()
        
        //path consists only of one fixed point
        if path.points.count == 1 {
            path.removeLastPoint()
            curveDesigner.activePath = nil
            path.removeFromParentNode()
        }
        
        //no points left - can only happen from undoing
        else if path.points.count == 0 {
            curveDesigner.activePath = nil
            path.removeFromParentNode()
        }
        
        //path consits of more
        else {
            path.removeLastPoint()
            //new active point
            let newNode = ARPPathNode(self.inScene.pencilPoint.position, cornerStyle: pathNode.cornerStyle)
            path.appendPoint(newNode)
            
        }
    }
    
    override func redo() {
        
        originalPoints.filter({ !$0.fixed }).forEach({ $0.removeFromParentNode() })
        originalPoints.removeAll(where: { !$0.fixed })
        
        curveDesigner.activePath = nil
        
        for _ in path.points {
            path.removeLastPoint()
        }
        
        path.rebuild()
        path.removeFromParentNode()
        
        for point in originalPoints {
            path.appendPoint(point)
        }
        
        path.rebuild()
        inScene.drawingNode.addChildNode(path)
        
        curveDesigner.activePath = path
        let newNode = ARPPathNode(self.inScene.pencilPoint.position, cornerStyle: pathNode.cornerStyle)
        path.appendPoint(newNode)
        
    }

    
}
