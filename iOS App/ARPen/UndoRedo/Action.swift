//
//  Action.swift
//  ARPen
//
//  Created by Andreas RF Dymek on 29.12.20.
//  Copyright © 2020 RWTH Aachen. All rights reserved.
//

import Foundation



/// The base type for all Actions. Has to include the scene, possibly the occtReference of one geometry object, although simply storing the node could be easier for specific action types.
/// Each subclass of Action has to implement undo() / redo(), thus being able to undo and redo an Action.
/**
   
 */
public class Action {
    
    var inScene: PenScene
    var occtRef : OCCTReference?
    
    func undo(){}
    
    func redo(){}
    
    init(occtRef: OCCTReference, scene: PenScene){
        self.inScene = scene
        self.occtRef = occtRef
    }
    
    init(scene: PenScene){
        self.inScene = scene
    }
}
