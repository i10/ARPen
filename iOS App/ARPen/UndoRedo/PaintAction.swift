//
//  PaintAction.swift
//  ARPen
//
//  Created by Andreas RF Dymek on 08.01.21.
//  Copyright © 2021 RWTH Aachen. All rights reserved.
//

import Foundation

public class PaintAction : Action {
    
    private var line: [SCNNode]
        
    init(scene: PenScene, line: [SCNNode]){
        self.line = line
        super.init(scene: scene)
    }
    
    override func undo() {
        for cylinder in line {
            DispatchQueue.main.async {
                cylinder.removeFromParentNode()
            }
        }
        
    }
    
    override func redo() {
        for cylinder in line {
            DispatchQueue.main.async {
                self.inScene.drawingNode.addChildNode(cylinder)
            }
        }
    
    }
    
    
    
}
