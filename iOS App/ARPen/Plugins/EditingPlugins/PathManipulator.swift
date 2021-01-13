//
//  PathManipulator.swift
//  ARPen
//
//  Created by Andreas RF Dymek on 08.01.21.
//  Copyright © 2021 RWTH Aachen. All rights reserved.
//

import Foundation
import ARKit

class PathManipulator {
    
    var currentScene: PenScene?
    var currentView: ARSCNView?
    var urManager: UndoRedoManager?

    ///pathPartSelector - user selects two nodes and the line segment in between is chosen
    var pathPartSelector: [ARPPathNode] = []
    ///save Positions for undo/redo of node translation
    var saveInitPos: Bool = false
    var initialPosition: SCNVector3?
    var updatedPosition: SCNVector3?
    
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
    /// The currently edited path
    var activePath: ARPPath? = nil
    
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
    func activate(withScene scene: PenScene, andView view: ARSCNView, urManager: UndoRedoManager) {
        self.currentView = view
        self.currentScene = scene
        self.urManager = urManager
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
        
        //Currently hovering over a node
        if pathNodeHover != nil {
            // Start dragging when either the button has been held for long enough or pen has moved a certain distance.
            if (buttons[.Button2] ?? false)
                && ((Date() - (lastClickTime ?? Date())) > PathManipulator.timeTillDrag){
                
                if let target = pathNodeHover{
                    selectPathNode(target)
                    
                    //save the initial position for undo/redo
                    if !saveInitPos{
                        initialPosition = target.position
                        saveInitPos = true
                    }
                    
                    if ((lastPenPosition?.distance(vector: scene.pencilPoint.position) ?? 0) > PathManipulator.maxDistanceTillDrag){
                        dragging = true
                    }
                }
            }
            
        }
        
        //node is moved to the pencilPoint position
        if selectedPathNode != nil {
     
            if PathManipulator.snapWhenDragging
            {
                let path = selectedPathNode?.parent!.parent as! ARPPath
                activePath = path
            
                let shift = scene.pencilPoint.position - selectedPathNode!.position
                selectedPathNode!.localTranslate(by: shift)
            
                tryUpdatePath()
            }
            
            if dragging, let lastPos = lastPenPosition {
                selectedPathNode!.position += scene.pencilPoint.position - lastPos
                
                lastPenPosition = scene.pencilPoint.position
            }
        }
        
        //insert a node in the center of two nodes
        if pathPartSelector.count == 2 {
        
            let path = pathPartSelector[0].parent!.parent as! ARPPath
            
            activePath = path
                    
            let prevClosed = activePath!.closed
            let noOfNodes = activePath!.points.count
            var points = activePath!.points
            var index0: Int = 0
            var index1: Int = 0
                    
            for i in 0...noOfNodes-1{
                if pathPartSelector[0] == points[i]{
                    index0 = i
                }
                    
                if pathPartSelector[1] == points[i]{
                    index1 = i
                }
            }
                
            let pos = pathPartSelector[0].position + (1/2 * (pathPartSelector[1].position - pathPartSelector[0].position))
            var newPathNode = ARPPathNode(pos ,cornerStyle: pathPartSelector[0].cornerStyle)
            newPathNode.fixed = true
                
            //special case for selected nodes
            if (((index0 == 0 && index1 == noOfNodes-1) || (index0 == noOfNodes-1 && index1 == 0)) && prevClosed){
                //we use index0 for insertion of new node
                index0 = noOfNodes
            }
                
            //if index0 > index1 we dont need to change anything
                
            else if(index0 < index1){
                //we use index0 for insertion of new node
                index0 = index0 + 1
            }
                
            points.insert(newPathNode, at: index0)
            activePath?.points = []
            activePath?.closed = false
            for i in 0...points.count-1{
                activePath?.appendPoint(points[i])
            }
            
            if prevClosed {
                activePath!.closed = true
            }
    
            activePath!.rebuild()
            activePath!.flatten()
                
            for point in activePath!.points{
                point.geometryNode.geometry?.firstMaterial?.diffuse.contents = (point.cornerStyle == .sharp ? point.sharpColor : point.roundColor)
            }
             
            pathPartSelector.removeLast()
            pathPartSelector.removeLast()
            
            let insertedNodeAction = InsertedNodeAction(scene: self.currentScene!, atIndex: index0, path: activePath!, pathNode: newPathNode)
            self.urManager?.actionDone(insertedNodeAction)
        }
    }
    
    ///projects the pencilPoint on a given diagonal on the image plane
    /**
        
     */
    func projectOntoPathPart(pencilPoint: SCNVector3, start: SCNVector3, end: SCNVector3) -> CGPoint {
        let projP = projectOntoImagePlane(pointerPosition: pencilPoint)
        let projS = projectOntoImagePlane(pointerPosition: start)
        let projD = projectOntoImagePlane(pointerPosition: end)
        let DS = CGPoint(x: projS!.x - projD!.x, y: projS!.y - projD!.y)
        let DP = CGPoint(x: projP!.x - projD!.x, y: projP!.y - projD!.y)
        let scalar = (dotProduct(DP, DS) / dotProduct(DS, DS))
        let scalarDS = CGPoint(x: DS.x * scalar, y: DS.y * scalar)
        return projD! + scalarDS
    }
    
    ///project a point onto Screen Coordinates / Image Plane
    /**
        
     */
    func projectOntoImagePlane(pointerPosition: SCNVector3) -> CGPoint? {
        guard let sceneView = self.currentView  else { return nil }
        let projectedPencilPosition = sceneView.projectPoint(pointerPosition)
        let projectedCGPoint = CGPoint(x: CGFloat(projectedPencilPosition.x), y: CGFloat(projectedPencilPosition.y))

        return projectedCGPoint
    }
    
    ///calculates the dotProduct of two given vectors
    /**
        
     */
    func dotProduct(_ vecA: CGPoint, _ vecB: CGPoint)-> CGFloat{
        return (vecA.x * vecB.x + vecA.y * vecB.y)
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
        
        //Selecting geometry shows skeleton
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
                    
                    //after path editing, rebuild the model to showcase the change
                    (activePath?.parent?.parent as? ARPSweep)?.rebuild()
                    
                    unselectTarget(target)
                }
            }
            
        case .Button2:
            lastClickPosition = currentScene?.pencilPoint.position
            lastPenPosition = currentScene?.pencilPoint.position
            lastClickTime = Date()
            
        case .Button3:
            
            if pathPartSelector.count <= 2
            {
                if let target = pathNodeHover{
                    //selecting
                    if pathPartSelector.count < 2 {
                        //selecting first node
                        if pathPartSelector.count == 0 {
                            if !pathPartSelector.contains(target){
                                pathPartSelector.append(target)
                                for pathNode in pathPartSelector{
                                    pathNode.geometryNode.geometry?.firstMaterial?.diffuse.contents = UIColor.white
                                }
                                break }
                        }
                        //selecting second node (must be only one line segment away)
                        if pathPartSelector.count == 1 {
                            let path = pathPartSelector[0].parent!.parent as! ARPPath
                            let noOfNodes = path.points.count
                            let points = path.points
                            var index0: Int = 0
                            var index1: Int = 0
                        
                            for i in 0...noOfNodes-1{
                                if pathPartSelector[0] == points[i]{
                                    index0 = i}
                                if target == points[i]{
                                    index1 = i}
                            }
                            if((index0 == 0 && index1 == noOfNodes-1) || (index1 == 0 && index0 == noOfNodes-1) || (index1 == index0+1) || (index0 == index1+1) )
                            {
                                pathPartSelector.append(target)
                                for pathNode in pathPartSelector{
                                    pathNode.geometryNode.geometry?.firstMaterial?.diffuse.contents = UIColor.white
                                }
                                break
                            }
                        }
                    }
                    
                    //deselecting
                    if pathPartSelector.contains(target){
                        target.geometryNode.geometry?.firstMaterial?.diffuse.contents  = (target.cornerStyle == .sharp ? target.sharpColor : target.roundColor)
                        pathPartSelector = pathPartSelector.filter({$0 != target})
                        break
                    }
                }
            }
        }
    }
    
    
    ///
    /**
        
     */
    func didReleaseButton(_ button: Button) {
        switch button {
        
        case .Button2:
          
            //when you started dragging the node, releasing the button stops dragging and also puts undo/redo action on the Stack
            if dragging {
                if selectedPathNode != nil {
                    
                    updatedPosition = selectedPathNode?.position
                    
                    let nodeTranslationAction = NodeTranslatedAction(scene: self.currentScene!, path: selectedPathNode!.parent!.parent as! ARPPath, node: selectedPathNode!, initialPosition: initialPosition!, updatedPosition: updatedPosition!, manipulator: self)
                    
                    self.urManager?.actionDone(nodeTranslationAction)
                    
                    deselectPathNode(selectedPathNode!)
                    selectedPathNode = nil
                    saveInitPos = false
                }
            }
            
            //single press changes nodes corner style
            if !justSelectedSomething, let node = pathNodeHover {
                if node.cornerStyle == CornerStyle.sharp{
                    node.cornerStyle = CornerStyle.round
                }
                    
                else {
                    node.cornerStyle = CornerStyle.sharp
                }
                    
                let path = node.parent!.parent as! ARPPath
                
                activePath = path
                    
                tryUpdatePath()
                
                let nodeStyleAction = NodeStyleChanged(scene: self.currentScene!, path: path, node: node, manipulator: self)
                self.urManager?.actionDone(nodeStyleAction)
                
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
        if ((target as? ARPBox == nil && target as? ARPPyramid == nil && target as? ARPCylinder == nil && target as? ARPSphere == nil && target as? ARPBoolNode == nil))
        {
            target.selected = true
            target.visited = true
            selectedTargets.append(target)
        }
        
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
    
    
    ///a hitTest for the ARPPath
    /**
        
     */
    func hitTestPath(pointerPosition: SCNVector3) -> (ARPPath?, SCNVector3?){
            guard let sceneView = self.currentView  else { return (nil, nil) }
            let projectedPencilPosition = sceneView.projectPoint(pointerPosition)
            let projectedCGPoint = CGPoint(x: CGFloat(projectedPencilPosition.x), y: CGFloat(projectedPencilPosition.y))
            
            // Cast a ray from that position and find the first ARPenNode
            let hitResults = sceneView.hitTest(projectedCGPoint, options: [SCNHitTestOption.searchMode : SCNHitTestSearchMode.all.rawValue])
           
        return (hitResults.filter( { $0.node != currentScene?.pencilPoint } ).first?.node.parent as? ARPPath, hitResults.first?.worldCoordinates)
    }
    
    ///
    /**
        
     */
    func didDoubleClick(_ button: Button) {
        
    }
    
}
