//
//  Arranger.swift
//  ARPen
//
//  Created by Jan Benscheid on 08.06.19.
//  Copyright © 2019 RWTH Aachen. All rights reserved.
//

import Foundation
import ARKit

/**
This class handles the selecting and arranging , as this functionality is shared across multiple plugins. An examplary usage can be seen in `CombinePluginTutorial.swift`.
*/

class Arranger {
    
    var currentScene: PenScene?
    var currentView: ARSCNView?
    var urManager: UndoRedoManager?
    
    ///needed for undo/redo
    var translationStarted: Bool?
    var initialPositions: [ARPGeomNode : SCNVector3]?
    var updatedPositions: [ARPGeomNode : SCNVector3]?
    
    /// The time (in seconds) after which holding the main button on an object results in dragging it.
    static let timeTillDrag: Double = 1
    /// The minimum distance to move the pen starting at an object while holding the main button which results in dragging it.
    static let maxDistanceTillDrag: Float = 0.015
    /// Move the object with its center to the pen tip when dragging starts.
    static let snapWhenDragging: Bool = true
    
    //hoverTarget uses didSet to update any dependency automatically
    var hoverTarget: ARPGeomNode? {
        didSet {
            if let old = oldValue {
                old.highlighted = false
            }
            if let target = hoverTarget {
                target.highlighted = true
            }
        }
    }
    
    //selectedTargets is the Array of selected ARPGeomNodes
    var selectedTargets: [ARPGeomNode] = []
    
    var dragging: Bool = false
    private var buttonEvents: ButtonEvents
    private var justSelectedSomething = false
    
    private var lastClickPosition: SCNVector3?
    private var lastClickTime: Date?
    private var lastPenPosition: SCNVector3?
    
    var didSelectSomething: ((ARPGeomNode) -> Void)?
    
    init() {
        buttonEvents = ButtonEvents()
        buttonEvents.didPressButton = self.didPressButton
        buttonEvents.didReleaseButton = self.didReleaseButton
        buttonEvents.didDoubleClick = self.didDoubleClick
    }

    func activate(withScene scene: PenScene, andView view: ARSCNView, urManager: UndoRedoManager) {
        self.currentView = view
        self.currentScene = scene
        self.urManager = urManager
        self.dragging = false
        self.justSelectedSomething = false
        self.lastClickPosition = nil
        self.lastClickTime = nil
        self.lastPenPosition = nil
        self.translationStarted = false
    }

    func deactivate() {
        for target in selectedTargets {
            unselectTarget(target)
        }
    }
    
    func update(scene: PenScene, buttons: [Button : Bool]) {
        buttonEvents.update(buttons: buttons)
       
        
        if let hit = hitTest(pointerPosition: scene.pencilPoint.position) {
            hoverTarget = hit
        } else {
            hoverTarget = nil
        }
        
        // Start dragging when either the button has been held for long enough or pen has moved a certain distance.
        if (buttons[.Button1] ?? false)
            && ((Date() - (lastClickTime ?? Date())) > Arranger.timeTillDrag
                || (lastPenPosition?.distance(vector: scene.pencilPoint.position) ?? 0) > Arranger.maxDistanceTillDrag) {
            
            dragging = true
            
            if self.translationStarted == false {
                
                initialPositions = [:]
                
                for target in selectedTargets {
                    let node = target
                    initialPositions?.updateValue(target.position, forKey: node)
                }
               
                self.translationStarted = true
            }
            
            if Arranger.snapWhenDragging
            {
            
                let center = selectedTargets.reduce(SCNVector3(0,0,0), { $0 + $1.convertPosition($1.geometryNode.boundingSphere.center, to: self.currentScene?.drawingNode) }) / Float(selectedTargets.count)
                
                let shift = scene.pencilPoint.position - center
                
                for target in selectedTargets
                {
                    target.position += shift
                }
                    
            }
        }
        
        if dragging, let lastPos = lastPenPosition {
            for target in selectedTargets {
                target.position += scene.pencilPoint.position - lastPos
            }
            lastPenPosition = scene.pencilPoint.position
        }
    }
    
    func didPressButton(_ button: Button) {
        
        switch button {
        
        case .Button1:
            lastClickPosition = currentScene?.pencilPoint.position
            lastPenPosition = currentScene?.pencilPoint.position
            lastClickTime = Date()
            
            if let target = hoverTarget
            {
                if !selectedTargets.contains(target) {
                    selectTarget(target)
                    
                }
            }
            
            else {
                for target in selectedTargets {
                    unselectTarget(target)
                }
            }
            
        default:
            break
        }
    }
    
    func didReleaseButton(_ button: Button) {
        switch button {
        case .Button1:
            if dragging
            {
                for target in selectedTargets {
                    DispatchQueue.global(qos: .userInitiated).async {
                        // Do this in the background, as it may cause a time-intensive rebuild in the parent object
                        target.applyTransform()
                    }
                }
                
                self.translationStarted = false
                
                updatedPositions = [:]
                
                for target in selectedTargets {
                    updatedPositions?.updateValue(target.position, forKey: target)
                }
                
                let translationAction = TranslationAction(scene: self.currentScene!, initialPositions: initialPositions!, updatedPositions: updatedPositions!)
                urManager?.actionDone(translationAction)
                
            }
            
            else
            {
                if let target = hoverTarget, !justSelectedSomething {
                    if selectedTargets.contains(target) {
                        unselectTarget(target)
                    }
                }
            }
            justSelectedSomething = false
            lastPenPosition = nil
            dragging = false
            
        default:
            break
        }
    }
    
    
    
    func didDoubleClick(_ button: Button) {
      //removed on purpose
    }
    
    
    
    
    func selectTarget(_ target: ARPGeomNode) {
        target.selected = true
        selectedTargets.append(target)
        justSelectedSomething = true
        didSelectSomething?(target)
    }
    
    
    func unselectTarget(_ target: ARPGeomNode) {
        target.selected = false
        selectedTargets.removeAll(where: { $0 === target })
    }
    
    
    //hitTest
    func hitTest(pointerPosition: SCNVector3) -> ARPGeomNode? {
            guard let sceneView = self.currentView  else { return nil }
            let projectedPencilPosition = sceneView.projectPoint(pointerPosition)
            let projectedCGPoint = CGPoint(x: CGFloat(projectedPencilPosition.x), y: CGFloat(projectedPencilPosition.y))
            
            // Cast a ray from that position and find the first ARPenNode
            let hitResults = sceneView.hitTest(projectedCGPoint, options: [SCNHitTestOption.searchMode : SCNHitTestSearchMode.all.rawValue])
           
            return hitResults.filter( { $0.node != currentScene?.pencilPoint } ).first?.node.parent as? ARPGeomNode
    }
}
