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
    
    var notifier: UndoRedoManagerNotifier? = nil
    
    public func actionDone(_ action: Action) {
        undoStack.push(action)
    }
    
    public func undo(){
        if undoStack.count != 0 {
            let lastAction = undoStack.pop()
            lastAction?.undo()
            redoStack.push(lastAction!)
            
            if let notifier = notifier {
                  notifier.actionUndone(self)
            }
        }
    }
    
    public func redo(){
        if redoStack.count != 0 {
            let lastAction = redoStack.pop()
            lastAction?.redo()
            undoStack.push(lastAction!)
            
            if let notifier = notifier {
                  notifier.actionRedone(self)
            }
        }
        
    }
    
}

protocol UndoRedoManagerNotifier {
    func actionUndone(_ manager: UndoRedoManager)
    func actionRedone(_ manager: UndoRedoManager)
}
