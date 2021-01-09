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
        
        //if sweep/revolve/loft remove all the previous path actions...
        if ((action as? SweepBuildingAction) != nil) || ((action as? RevolveBuildingAction) != nil) || ((action as? LoftBuildingAction) != nil) || ((action as? ExpandingLoftAction != nil)){
            
            removePathActions()
        }

        undoStack.push(action)
        
    }
    
    func removePathActions(){
        let k = undoStack.count
        
        if k >= 1{
            for _ in 1...k{
                if ((undoStack.peek() as? PathAction) != nil){
                        _ = undoStack.pop()
                }
                
                else if ((redoStack.peek() as? PathAction) != nil){
                    _ = redoStack.pop()
                }
            }
        }
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
