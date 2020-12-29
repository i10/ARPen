//
//  UndoRedoManager.swift
//  ARPen
//
//  Created by Andreas RF Dymek on 29.12.20.
//  Copyright © 2020 RWTH Aachen. All rights reserved.
//

import Foundation

class UndoRedoManager {
    
    var undoStack = Stack<Action>()
    var redoStack = Stack<Action>()
    
    public func actionDone(_ action: Action) {
        undoStack.push(action)
    }
    
    public func undo(){
        if undoStack.count != 0 {
            let lastAction = undoStack.pop()
            lastAction?.undo()
            redoStack.push(lastAction!)
        }
    }
    
    public func redo(){
        if redoStack.count != 0 {
            let lastAction = redoStack.pop()
            lastAction?.redo()
            redoStack.push(lastAction!)
        }
        
    }
    
    
    
}
