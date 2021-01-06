//
//  BuildingAction.swift
//  ARPen
//
//  Created by Andreas RF Dymek on 29.12.20.
//  Copyright © 2020 RWTH Aachen. All rights reserved.
//

import Foundation

public class PrimitiveBuildingAction : Action {
    
    private let geometry: Any?
        
    init(occtRef: OCCTReference, scene: PenScene, sphere: ARPSphere){
        self.geometry = sphere
        super.init(occtRef: occtRef, scene: scene)
    }
    
    init(occtRef: OCCTReference, scene: PenScene, box: ARPBox){
        self.geometry = box
        super.init(occtRef: occtRef, scene: scene)
    }
    
    init(occtRef: OCCTReference, scene: PenScene, cylinder: ARPCylinder){
        self.geometry = cylinder
        super.init(occtRef: occtRef, scene: scene)
    }
    
    init(occtRef: OCCTReference, scene: PenScene, pyramid: ARPPyramid){
        self.geometry = pyramid
        super.init(occtRef: occtRef, scene: scene)
    }
    
    override func undo() {
        DispatchQueue.main.async
        {
            let geometryNode = self.geometry as? ARPGeomNode
            geometryNode?.removeFromParentNode()
        }
        
    }
    
    override func redo() {
        DispatchQueue.main.async
        {
            let geometryNode = self.geometry as? ARPGeomNode
            self.inScene.drawingNode.addChildNode(geometryNode!)
        }
    }
}


public class SweepBuildingAction : Action {
    
    public var sweep: ARPSweep
    
    init(occtRef: OCCTReference, scene: PenScene, sweep: ARPSweep){
        self.sweep = sweep
        super.init(occtRef: occtRef, scene: scene)
    }
  
    override func undo() {
        DispatchQueue.main.async
        {
            self.sweep.removeFromParentNode()
        }
        
    }
    
    override func redo() {
        DispatchQueue.main.async
        {
            self.inScene.drawingNode.addChildNode(self.sweep)
        }
    }
}

public class RevolveBuildingAction : Action {
    
    public var revolve: ARPRevolution
    
    init(occtRef: OCCTReference, scene: PenScene, revolve: ARPRevolution){
        self.revolve = revolve
        super.init(occtRef: occtRef, scene: scene)
    }
  
    override func undo() {
        DispatchQueue.main.async
        {
            self.revolve.removeFromParentNode()
        }
        
    }
    
    override func redo() {
        DispatchQueue.main.async
        {
            self.inScene.drawingNode.addChildNode(self.revolve)
        }
    }
}



public class LoftBuildingAction : Action {
    
    public var loft: ARPLoft
    
    init(occtRef: OCCTReference, scene: PenScene, loft: ARPLoft){
        self.loft = loft
        super.init(occtRef: occtRef, scene: scene)
    }
  
    override func undo() {
        DispatchQueue.main.async
        {
            self.loft.removeFromParentNode()
        }
        
    }
    
    override func redo() {
        DispatchQueue.main.async
        {
            self.inScene.drawingNode.addChildNode(self.loft)
        }
    }
}





