//
//  TranslationAction.swift
//  ARPen
//
//  Created by Andreas RF Dymek on 29.12.20.
//  Copyright © 2020 RWTH Aachen. All rights reserved.
//

import Foundation

public class TranslationAction : Action {
    
    private let initialPositions: [ARPGeomNode : SCNVector3]
    private let updatedPositions: [ARPGeomNode : SCNVector3]
    
    init(scene: PenScene, initialPositions: [ARPGeomNode : SCNVector3], updatedPositions: [ARPGeomNode : SCNVector3]){
        self.initialPositions = initialPositions
        self.updatedPositions = updatedPositions
        super.init(scene: scene)
    }
    
    override func undo() {
        
        for (node, pos) in initialPositions {
            node.position = pos
            node.applyTransform()
        }
        
    }
    
    override func redo() {
        
        for (node, pos) in updatedPositions {
            node.position = pos
            node.applyTransform()
        }
        
    }
    
    
}
