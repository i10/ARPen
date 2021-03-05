//
//  UndoRedoManager.swift
//  ARPen
//
//  Created by Andreas RF Dymek on 29.12.20.
//  Copyright © 2020 RWTH Aachen. All rights reserved.
//

import Foundation

/// The Manager for two Stacks, one being the undoStack and the other being the redoStack, consisting of Actions. See Action for more details. When the undo() function is called, an action is "undone" and pushed onto the redoStack. Calling redo() "redoes" the action and pushes it on the undoStack. Also contains the UndoRedoManagerNotifier which is a protocol that is used to send notifications to classes which need to know, when an action is undone. The "PenRayScaler" is a good example of that.
/// The active reference to the running UndoRedoManager is stored in the "PluginManager". Each plugin contains a reference to this class.
/**
    If you want to notify an class whenever an Action is undone/redone, do it like in this example
        
        extension PenRayScaler : UndoRedoManagerNotifier{
             func actionUndone(_ manager: UndoRedoManager)
             {
                 ...
             }
             
             func actionRedone(_ manager: UndoRedoManager)
             {
                ...
             }
        }
 
    As an example, here is how you should use the UndoRedoManager when you want to store an Action:

        let scalingAction = CornerScalingAction(...)
        self.urManager?.actionDone(scalingAction)
        
 */

class UndoRedoManager {
    
    var undoStack = Stack<Action>()
    var redoStack = Stack<Action>()
    var notifier: UndoRedoManagerNotifier? = nil
    
    //this function should be called whenever an Action is created in the code. Pushes the action onto the undoStack and thus allows undoing/redoing the action.
    public func actionDone(_ action: Action) {
        
        //if Sweep/Revolve/Loft Building Action were done, remove all the previous Path Actions...
        if ((action as? SweepBuildingAction) != nil) || ((action as? RevolveBuildingAction) != nil) || ((action as? LoftBuildingAction) != nil) || ((action as? ExpandingLoftAction != nil))
        {
            removePathActions()
        }

        undoStack.push(action)
    }
    
    
    //self explaining title: removes all pathactions from undo/redoStack
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
    
    //undoing an action. pushes the action onto the redo stack
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
    
    //redoing an action. pushes the action on the undo stack
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
    
    public func resetUndoRedoManager() {
        self.undoStack.clear()
        self.redoStack.clear()
    }
    
}

protocol UndoRedoManagerNotifier {
    func actionUndone(_ manager: UndoRedoManager)
    func actionRedone(_ manager: UndoRedoManager)
}
