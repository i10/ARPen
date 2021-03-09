//
//  SolidOrHoleAction.swift
//  ARPen
//
//  Created by Andreas RF Dymek on 08.01.21.
//  Copyright © 2021 RWTH Aachen. All rights reserved.
//

import Foundation

public class SolidOrHoleAction : Action {
    
    var target: ARPGeomNode
    var isHole: Bool
    
    init(scene: PenScene, target: ARPGeomNode){
        self.target = target
        self.isHole = target.isHole
        super.init(scene: scene)
    }
  
    override func undo() {
        target.isHole = !self.isHole
    }
    
    override func redo() {
        target.isHole = self.isHole
    }
}
