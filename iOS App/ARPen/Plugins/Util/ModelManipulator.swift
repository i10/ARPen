//
//  ModelManipulator.swift
//  ARPen
//
//  Created by Andreas Dymek on 11.12.2020
//  Copyright © 2020 RWTH Aachen. All rights reserved.
//

import Foundation
import ARKit



class ModelManipulator {
    
    var currentScene: PenScene?
    var currentView: ARSCNView?
    
    /// The currently edited path
    var activePath: ARPPath? = nil
    /// true, if the path is currently being calculated in parallel in the backend, to reduce redundant calculations
    private var busy: Bool = false
    
    /// The time (in seconds) after which holding the main button on an object results in dragging it.
    static let timeTillDrag: Double = 1
    /// The minimum distance to move the pen starting at an object while holding the main button which results in dragging it.
    static let maxDistanceTillDrag: Float = 0.015
    /// Move the object with its center to the pen tip when dragging starts.
    static let snapWhenDragging: Bool = true
    
    //pathNodeHover uses didSet to update any dependency automatically
    var pathNodeHover: ARPPathNode? {
        didSet {
            if let old = oldValue {
                old.highlighted = false
            }
            if let target = pathNodeHover {
                target.highlighted = true
            }
        }
    }
    
    //the PathNode that is selected for editing
    var selectedPathNode: ARPPathNode?
    
    var dragging: Bool = false
    private var buttonEvents: ButtonEvents
    private var justSelectedSomething = false
    
    private var lastClickPosition: SCNVector3?
    private var lastClickTime: Date?
    private var lastPenPosition: SCNVector3?
    
    var didSelectSomething: ((ARPPathNode) -> Void)?
    
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
    
    
    
    
    ///
    /**
        
     */
    init() {
        buttonEvents = ButtonEvents()
        buttonEvents.didPressButton = self.didPressButton
        buttonEvents.didReleaseButton = self.didReleaseButton
        buttonEvents.didDoubleClick = self.didDoubleClick
        self.busy = false
        self.activePath = nil
    }
    
    ///
    /**
        
     */
    func activate(withScene scene: PenScene, andView view: ARSCNView) {
        self.currentView = view
        self.currentScene = scene
        self.dragging = false
        self.justSelectedSomething = false
        self.lastClickPosition = nil
        self.lastClickTime = nil
        self.lastPenPosition = nil
    }

    ///
    /**
        
     */
    func deactivate() {
        for target in selectedTargets {
            unselectTarget(target)
        }
    }
    
 
    ///
    /**
        
     */
    func update(scene: PenScene, buttons: [Button : Bool]) {
        buttonEvents.update(buttons: buttons)
       
        //Checking for geometry to hit
        if let hit = hitTestGeometry(pointerPosition: scene.pencilPoint.position) {
            hoverTarget = hit
        } else {
            hoverTarget = nil
        }
        
        //Checking for a ARPPathNode to hit
        if let pathNodeHit = hitTestPathNodes(pointerPosition: scene.pencilPoint.position) {
            pathNodeHover = pathNodeHit
        } else {
            pathNodeHover = nil
        }
        
        
        //moving
        if selectedPathNode != nil {
           
            // Start dragging when either the button has been held for long enough or pen has moved a certain distance.
            if (buttons[.Button2] ?? false)
                && ((Date() - (lastClickTime ?? Date())) > ModelManipulator.timeTillDrag
                    || (lastPenPosition?.distance(vector: scene.pencilPoint.position) ?? 0) > ModelManipulator.maxDistanceTillDrag) {
                
                dragging = true
                
                if ModelManipulator.snapWhenDragging {
                        
                    let path = selectedPathNode?.parent!.parent as! ARPPath
                    activePath = path
                    
                    print("ModelMan: \(activePath?.occtReference)")
                  
                    let shift = scene.pencilPoint.position - selectedPathNode!.position
                    selectedPathNode!.localTranslate(by: shift)
                    
                    
                    tryUpdatePath()
                }
            }
            
            if dragging, let lastPos = lastPenPosition {
                selectedPathNode!.position += scene.pencilPoint.position - lastPos
                
                lastPenPosition = scene.pencilPoint.position
            }
        
        }
       
    }
    
   

    func tryUpdatePath() {
        if !busy, let path = activePath {
            busy = true
            DispatchQueue.global(qos: .userInitiated).async {
                path.update()
                self.busy = false
            }
        }
    }


    ///
    /**
        
     */
    func didPressButton(_ button: Button) {
        
        switch button {
        
        //Showing skeleton and selecting geometry
        case .Button1:
            if let target = hoverTarget {
                
                if selectedTargets.count != 1{
                    selectTarget(target)
                }
            }
            
            else {
                for target in selectedTargets {
                    if (selectedPathNode != nil){
                        deselectPathNode(selectedPathNode!)
                    }
                    activePath?.flatten()
                    (activePath?.parent?.parent as? ARPGeomNode)?.rebuild()
                    
                    unselectTarget(target)
                }
            }
        
        //selecting an ARPPathNode
        case .Button2:
            lastClickPosition = currentScene?.pencilPoint.position
            lastPenPosition = currentScene?.pencilPoint.position
            lastClickTime = Date()
            
            if let target = pathNodeHover {
                
                if selectedPathNode == nil{
                    selectPathNode(target)
                }
            }
            
            else {
                if selectedPathNode != nil {
                    deselectPathNode(selectedPathNode!)
                    selectedPathNode = nil
                }
            }
            
      
        default:
            break
        }
    }
    
    
    ///
    /**
        
     */
    func didReleaseButton(_ button: Button) {
        switch button {
        
        case .Button2:
            
            if dragging {
               
            }
            
            else {
                if !justSelectedSomething, pathNodeHover != nil, selectedPathNode != nil {
                    deselectPathNode(selectedPathNode!)
                }
            }
            
            justSelectedSomething = false
            lastPenPosition = nil
            dragging = false
    
            
        default:
            break
        }
    }
   
    ///
    /**
        
     */
    func selectPathNode(_ target: ARPPathNode) {
        target.selected = true
        selectedPathNode = target
        justSelectedSomething = true
        didSelectSomething?(target)
        
        
        
    }
    
    ///
    /**
        
     */
    func deselectPathNode(_ target: ARPPathNode) {
        target.selected = false
        selectedPathNode = nil
        
        
    }
    
    
    
    ///
    /**
        
     */
    func selectTarget(_ target: ARPGeomNode) {
        target.selected = true
        target.visited = true
        selectedTargets.append(target)
        
    }
    
    ///
    /**
        
     */
    func unselectTarget(_ target: ARPGeomNode) {
        target.selected = false
        target.visited = false
        selectedTargets.removeAll(where: { $0 === target })
    }
    

    
    ///Hit test for the geomtry in the scene
    /**
        
     */
    func hitTestGeometry(pointerPosition: SCNVector3) -> ARPGeomNode? {
            guard let sceneView = self.currentView  else { return nil }
            let projectedPencilPosition = sceneView.projectPoint(pointerPosition)
            let projectedCGPoint = CGPoint(x: CGFloat(projectedPencilPosition.x), y: CGFloat(projectedPencilPosition.y))
            
            // Cast a ray from that position and find the first ARPenNode
            let hitResults = sceneView.hitTest(projectedCGPoint, options: [SCNHitTestOption.searchMode : SCNHitTestSearchMode.all.rawValue])
           
            return hitResults.filter( { $0.node != currentScene?.pencilPoint } ).first?.node.parent as? ARPGeomNode
    }
    
    
    ///a hitTest for the ARPPathNodes
    /**
        
     */
    func hitTestPathNodes(pointerPosition: SCNVector3) -> ARPPathNode? {
            guard let sceneView = self.currentView  else { return nil }
            let projectedPencilPosition = sceneView.projectPoint(pointerPosition)
            let projectedCGPoint = CGPoint(x: CGFloat(projectedPencilPosition.x), y: CGFloat(projectedPencilPosition.y))
            
            // Cast a ray from that position and find the first ARPenNode
            let hitResults = sceneView.hitTest(projectedCGPoint, options: [SCNHitTestOption.searchMode : SCNHitTestSearchMode.all.rawValue])
           
            return hitResults.filter( { $0.node != currentScene?.pencilPoint } ).first?.node.parent as? ARPPathNode
    }
    
    ///
    /**
        
     */
    func didDoubleClick(_ button: Button) {
        
    }
    
}
