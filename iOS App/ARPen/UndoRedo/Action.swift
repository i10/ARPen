//
//  Action.swift
//  ARPen
//
//  Created by Andreas RF Dymek on 29.12.20.
//  Copyright © 2020 RWTH Aachen. All rights reserved.
//

import Foundation

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
