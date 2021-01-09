//
//  ManipulationAction.swift
//  ARPen
//
//  Created by Andreas RF Dymek on 29.12.20.
//  Copyright © 2020 RWTH Aachen. All rights reserved.
//

import Foundation

public class InsertedNodeAction : Action {
    
    var atIndex: Int
    var pathNode: ARPPathNode
    var path: ARPPath
    
    init(scene: PenScene, atIndex: Int, path: ARPPath, pathNode: ARPPathNode){
        self.atIndex = atIndex
        self.pathNode = pathNode
        self.path = path
        super.init(scene: scene)
    }
    
    override func undo() {
        var points = path.points
        let prevClosed = path.closed
        
        points.filter({ $0 == pathNode }).forEach({ $0.removeFromParentNode() })
        points.removeAll(where: { $0 == pathNode })
        
        for _ in path.points {
            path.removeLastPoint()
        }
        
        path.closed = false
    
        for point in points {
            path.appendPoint(point)
        }
        
        if prevClosed {
            path.closed = true
        }
        path.removeNonFixedPoints()
        path.rebuild()
        path.flatten()
    }
    
    override func redo() {
        var points = path.points
        let prevClosed = path.closed
        
        points.insert(pathNode, at: atIndex)
        
        path.points = []
        path.closed = false
        for i in 0...points.count-1{
            path.appendPoint(points[i])
        }
        
        if prevClosed {
            path.closed = true
        }

        path.rebuild()
        path.flatten()
    }
}



public class NodeTranslatedAction : Action {
    
    var node: ARPPathNode
    var path: ARPPath
    var initialPosition: SCNVector3
    var updatedPosition: SCNVector3
    var manipulator: PathManipulator
    
    init(scene: PenScene, path: ARPPath, node: ARPPathNode, initialPosition: SCNVector3, updatedPosition: SCNVector3, manipulator: PathManipulator){
        self.node = node
        self.path = path
        self.manipulator = manipulator
        self.initialPosition = initialPosition
        self.updatedPosition = updatedPosition
        super.init(scene: scene)
    }
    
    override func undo() {
        node.position = initialPosition
        path.flatten()
        path.rebuild()
        manipulator.activePath = path
        manipulator.tryUpdatePath()
    }
    
    override func redo() {
        node.position = updatedPosition
        path.flatten()
        path.rebuild()
        manipulator.activePath = path
        manipulator.tryUpdatePath()
    }
}



public class NodeStyleChanged : Action {
    var node: ARPPathNode
    var path: ARPPath
    var manipulator: PathManipulator
    
    init(scene: PenScene, path: ARPPath, node: ARPPathNode, manipulator: PathManipulator){
        self.node = node
        self.path = path
        self.manipulator = manipulator
        super.init(scene: scene)
    }
    
    override func undo() {
        if node.cornerStyle == CornerStyle.sharp
        {
            node.cornerStyle = CornerStyle.round
        }
            
        else
        {
            node.cornerStyle = CornerStyle.sharp
        }
        
        manipulator.activePath = path
        manipulator.tryUpdatePath()
        
        
    }
    
    override func redo() {
        if node.cornerStyle == CornerStyle.sharp
        {
            node.cornerStyle = CornerStyle.round
        }
            
        else
        {
            node.cornerStyle = CornerStyle.sharp
        }
        
        manipulator.activePath = path
        manipulator.tryUpdatePath()
    }
   
}
