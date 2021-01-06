//
//  BooleanAction.swift
//  ARPen
//
//  Created by Andreas RF Dymek on 04.01.21.
//  Copyright © 2021 RWTH Aachen. All rights reserved.
//

import Foundation

public class BooleanAction : Action {
    
    private var boolNode: ARPBoolNode
        
    init(occtRef: OCCTReference, scene: PenScene, boolNode: ARPBoolNode){
        self.boolNode = boolNode
        super.init(occtRef: occtRef, scene: scene)
    }
    
    override func undo() {
        
        let a = boolNode.a
        let b = boolNode.b
       
        
        DispatchQueue.main.async {
            self.inScene.drawingNode.addChildNode(a)
            self.inScene.drawingNode.addChildNode(b)
            self.boolNode.removeFromParentNode()
        }
    }
    
    override func redo() {
        
        let operation = boolNode.operation
        let a = boolNode.a
        let b = boolNode.b
        
       
        DispatchQueue.global(qos: .userInitiated).async {
            if let redoneBoolNode = try? ARPBoolNode(a: a, b: b, operation: operation)
            {
                DispatchQueue.main.async
                {
                    self.boolNode = redoneBoolNode
                    self.inScene.drawingNode.addChildNode(self.boolNode)
                }
            }
        }
    
    }
    
    
    
}
