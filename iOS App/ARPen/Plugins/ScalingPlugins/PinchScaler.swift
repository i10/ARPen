//
//  PinchScaler.swift
//  ARPen
//
//  Created by Andreas RF Dymek on 25.12.20.
//  Copyright © 2020 RWTH Aachen. All rights reserved.
//

import Foundation
import ARKit

/**
This class handles the "visiting" and selecting of meshes. When one mesh is selected the boundingBox corners are also visualized. We hover over corerns and then select them using the PenRayScaling Plugin. Scaling then happens in the update method.
 
 Scaling is supporred for one selected mesh. Mulitple selection is not possible.
 Some code was inspired by the work of Farhadiba Mohammed on ARPen.
*/
class PinchScaler {
    
    var currentScene: PenScene?
    var currentView: ARSCNView?
    var urManager: UndoRedoManager?
    var tapGesture : UITapGestureRecognizer?
    var pinchGesture: UIPinchGestureRecognizer?
    
    //everything needed for undo/redo
    var initialScale: SCNVector3?
    var updatedScale: SCNVector3?
    var diagonalNodeBefore: SCNNode?
    var diffInScale: SCNVector3?
    var active: Bool?
    
    private var buttonEvents: ButtonEvents
    private var lastClickPosition: SCNVector3?
    public var lastClickTime: Date?
    private var lastPenPosition: SCNVector3?
    
    /// The time (in seconds) after which holding the main button on an object results in dragging it.
    let timeTillDrag: Double = 0.5
    /// The minimum distance to move the pen starting at an object while holding the main button which results in dragging it.
    static let maxDistanceTillDrag: Float = 0.015
    /// Move the object with its center to the pen tip when dragging starts.
    static let snapWhenDragging: Bool = true
    var positionSave: SCNVector3?
    ///the currently selected corner of the meshes bounding box
    var selectedCorner: SCNNode?
    ///the corner the pencilPoint hovers over
    var hoverCorner: SCNNode?
    ///boolean which indicates if a corner is currently selected
    var isACornerSelected: Bool = false
    var dragging: Bool = false

    var prevRecScaleByOCCTRef: [String: CGFloat] = [:]
    
    
    
    
    ///for selecting geometry
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

    //selectedTargets is the Array of selected ARPNodes
    var selectedTargets: [ARPGeomNode] = []
    var visitTarget: ARPGeomNode?
    var didSelectSomething: ((ARPGeomNode) -> Void)?
    private var geometrySelected = false

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
        self.active = true
        
        self.urManager?.notifier = self
        
        self.tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        self.currentView?.addGestureRecognizer(tapGesture!)
        self.currentView?.isUserInteractionEnabled = true
        
        self.pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(self.handlePinch(_:)))
        self.currentView?.addGestureRecognizer(pinchGesture!)
        self.currentView?.isUserInteractionEnabled = true
        
        self.isACornerSelected = false
        self.visitTarget = nil
        self.dragging = false
        self.lastClickPosition = nil
        self.lastClickTime = nil
        self.lastPenPosition = nil
    }

    func deactivate() {
        self.active = false
        
        for target in selectedTargets {
            unselectTarget(target)
        }
        
        if let tapGestureRecognizer = self.tapGesture{
            self.currentView?.removeGestureRecognizer(tapGestureRecognizer)
        }
        
        if let pinchGestureRecognizer = self.pinchGesture{
            self.currentView?.removeGestureRecognizer(pinchGestureRecognizer)
        }
    }
    
    //function for selecting objects via touchscreen
    @objc func handleTap(_ sender: UITapGestureRecognizer){
        
        let touchPoint = sender.location(in: self.currentView)
        
        if geometrySelected == false
        {
            let hitResults = self.currentView!.hitTest(touchPoint, options: [SCNHitTestOption.searchMode : SCNHitTestSearchMode.all.rawValue] )
            
            if let hit = hitResults.first?.node.parent as? ARPGeomNode {
                hoverTarget = hit
                selectTarget(hit)
            }
        }
        
        else
        {
            //deselecting geometry
            let hitResults = self.currentView!.hitTest(touchPoint, options: [SCNHitTestOption.searchMode : SCNHitTestSearchMode.all.rawValue] )
            
            if let hit = hitResults.first?.node.parent as? ARPGeomNode {
                if selectedTargets.first == hit
                {
                    hoverTarget = nil
                    unselectTarget(hit)
                    selectedCorner = nil
                    isACornerSelected = false  
                }
            }
            
            //selecting corner
            let namesOfCorners = ["lbd", "rbd", "lbu", "rbu", "lfd", "rfd", "lfu", "rfu"]
            
            let cornerHit = hitResults.filter( {namesOfCorners.contains($0.node.name ?? "empty") }).first?.node as SCNNode?
            
            if namesOfCorners.contains(cornerHit?.name ?? "empty")
            {
                //selecting corner
                if(isACornerSelected == false)
                {
                    cornerHit?.geometry?.firstMaterial?.diffuse.contents = UIColor.init(hue: 216/360, saturation: 68/100, brightness: 68/100, alpha: 1.0)
                    selectedCorner = cornerHit
                    positionSave = selectedCorner?.position
                    isACornerSelected = true
                }
                
                //deselecting corner
                else if(isACornerSelected == true && cornerHit == selectedCorner)
                {
                    cornerHit?.geometry?.firstMaterial?.diffuse.contents = UIColor.init(hue: 216/360, saturation: 68/100, brightness: 38/100, alpha: 1.0)
                    selectedCorner = nil
                    positionSave = nil
                    isACornerSelected = false
                }

            }

        }
    }
 
    //function for scaling object by pulling a corner
    @objc func handlePinch(_ recognizer: UIPinchGestureRecognizer) {
        if geometrySelected == true && selectedCorner != nil
        {
            if (recognizer.state == .began){
                
                let ref = selectedTargets.first?.occtReference!
                if (prevRecScaleByOCCTRef.keys.contains(ref!)){
                    recognizer.scale = prevRecScaleByOCCTRef[ref!]!
                }
                initialScale = selectedTargets.first?.scale
            }
            
            if (recognizer.state == .changed)
            {
                let diagonalNode = getDiagonalNode(selectedCorner: selectedCorner!)
                
                diagonalNodeBefore = diagonalNode
                let before = diagonalNode?.position
                
                let scaleFactor = Float(recognizer.scale)
                
                selectedTargets.first!.scale = SCNVector3(scaleFactor, scaleFactor, scaleFactor)
                
                self.updateBoundingBox(selectedTargets.first!)
                
                let after = getDiagonalNode(selectedCorner: selectedCorner!)?.position

                let upper = ["lbu", "rbu", "lfu", "rfu"]

                //the diagonal node is an upper node
                if(upper.contains((getDiagonalNode(selectedCorner: selectedCorner!)?.name)!)){
                        let x_of_diff = after!.x - before!.x
                        let y_of_diff = after!.y - before!.y
                        let z_of_diff = after!.z - before!.z

                        let diff = SCNVector3(x: x_of_diff, y: y_of_diff, z: z_of_diff)
                        selectedTargets.first!.position -= diff
                }
                                                                            
                else {
                    let x_of_diff = before!.x - after!.x
                    let y_of_diff = before!.y - after!.y
                    let z_of_diff = before!.z - after!.z

                    let diff = SCNVector3(x: x_of_diff, y: y_of_diff, z: z_of_diff)
                    selectedTargets.first!.position += diff
                }
                                        
                self.updateBoundingBox(selectedTargets.first!)
                
                prevRecScaleByOCCTRef.updateValue(recognizer.scale, forKey: selectedTargets.first!.occtReference!)
                
            }
            
            if (recognizer.state == .ended){
                if diagonalNodeBefore != nil {
                    updatedScale = selectedTargets.first?.scale
                    diffInScale =  updatedScale! - initialScale!
                    let scalingAction = CornerScalingAction(occtRef: selectedTargets.first!.occtReference!, scene: self.currentScene!, diffInScale: diffInScale!, diagonalNodeBefore: diagonalNodeBefore!)
                    self.urManager?.actionDone(scalingAction)
                }
            }
        }
    }

    ///gets executed each frame and is mainly responsible for scaling
    func update(scene: PenScene, buttons: [Button : Bool]) {
    
    }
    

    ///projects the pencilPoint on a given diagonal on the image plane
    /**
        
     */
    func projectOntoDiagonal(pencilPoint: SCNVector3, selectedCorner: SCNNode, diagonal: SCNVector3) -> CGPoint {
        
        let projP = projectOntoImagePlane(pointerPosition: pencilPoint)
        let projS = projectOntoImagePlane(pointerPosition: selectedCorner.position)
        let projD = projectOntoImagePlane(pointerPosition: diagonal)
            
        let DS = CGPoint(x: projS!.x - projD!.x, y: projS!.y - projD!.y)
            
        let DP = CGPoint(x: projP!.x - projD!.x, y: projP!.y - projD!.y)
            
        let scalar = (dotProduct(DP, DS) / dotProduct(DS, DS))
            
        let scalarDS = CGPoint(x: DS.x * scalar, y: DS.y * scalar)
            
        return projD! + scalarDS
    }
    
 
    func didPressButton(_ button: Button) {
        
        switch button {
        
        case .Button1:
           break
        
        case .Button2, .Button3:
          break
        }
    }
    
 
    func didReleaseButton(_ button: Button) {
        switch button {
        case .Button1:
           break
        
        case .Button2, .Button3:
            break
        
        }
    }
    
    ///get the diagonal Node of a selectedCorner
    /**
        
     */
    func getDiagonalNode(selectedCorner: SCNNode) -> SCNNode? {
        
        let name = selectedCorner.name
        
        if(name == "lbd")
        {
            return self.currentScene?.drawingNode.childNode(withName: "rfu", recursively: true)
        }
        
        if(name == "rfu")
        {
            return self.currentScene?.drawingNode.childNode(withName: "lbd", recursively: true)
        }
        
        if(name == "lbu"){
            return self.currentScene?.drawingNode.childNode(withName: "rfd", recursively: true)
        }
        
        if(name == "rfd"){
            return self.currentScene?.drawingNode.childNode(withName: "lbu", recursively: true)
        }
        
        if(name == "lfu")
        {
            return self.currentScene?.drawingNode.childNode(withName: "rbd", recursively: true)
        }
        
        if(name == "rbd")
        {
            return self.currentScene?.drawingNode.childNode(withName: "lfu", recursively: true)
        }
        
        if(name == "rbu")
        {
            return self.currentScene?.drawingNode.childNode(withName: "lfd", recursively: true)
        }
        
        if(name == "lfd")
        {
            return self.currentScene?.drawingNode.childNode(withName: "rbu", recursively: true)
        }
        
        return nil
    }

    ///visualize the bounding box  of a given target - draws all 8 bounding box corners in world coordinates of a given target as a dictionary. Identify corners in the dictionary via keys in format of "lbd" = left bottom down / "rfu" = right front up
    /**
        returns the corners as a dictionary. Keys are in the format, e.g. "lbd" or "rfu"
        l = left , r = right , b = back , f = front , d = down , u = up
     */
    func viewBoundingBox(_ target: ARPGeomNode) {
        
        let pitch = target.eulerAngles.x
        let yaw = target.eulerAngles.y
        let roll = target.eulerAngles.z
            
        target.eulerAngles = SCNVector3(0,0,0)
            
        //mincorner of bounding box
        let lbd = target.convertPosition(target.boundingBox.min, to: self.currentScene?.drawingNode)
        
        //maxcorner of bounding box
        let rfu = target.convertPosition(target.boundingBox.max, to: self.currentScene?.drawingNode)
     
        //Determine height and width of bounding box
        let height = rfu.y - lbd.y
        let width = rfu.x - lbd.x
        
        let rbd = lbd + SCNVector3(x: width, y: 0, z: 0)
        let lbu = lbd + SCNVector3(x: 0, y: height, z: 0)
        let rbu = lbu + SCNVector3(x: width, y: 0, z: 0)
        
        let rfd = rfu - SCNVector3(x: 0, y: height, z: 0)
        let lfu = rfu - SCNVector3(x: width, y: 0, z: 0)
        let lfd = lfu - SCNVector3(x: 0, y: height, z: 0)
       
        var corners: [String: SCNVector3] = ["lbd": lbd, "rbd": rbd, "lbu": lbu, "rbu": rbu, "lfd": lfd, "rfd": rfd, "lfu": lfu, "rfu": rfu]
        
        for (key , position) in corners {
            
            let tempPos = position - target.position
            
            let rotatedX = (cos(roll)*cos(yaw))*tempPos.x + (cos(roll)*sin(yaw)*sin(pitch)-sin(roll)*cos(pitch))*tempPos.y + (cos(roll)*sin(yaw)*cos(pitch)+sin(roll)*sin(pitch))*tempPos.z
            let rotatedY = (sin(roll)*cos(yaw))*tempPos.x + (sin(roll)*sin(yaw)*sin(pitch)+cos(roll)*cos(pitch))*tempPos.y + (sin(roll)*sin(yaw)*cos(pitch)-cos(roll)*sin(pitch))*tempPos.z
            let rotatedZ = (-sin(yaw))*tempPos.x + (cos(yaw)*sin(pitch))*tempPos.y + (cos(yaw)*cos(pitch))*tempPos.z
            
            corners[key] = SCNVector3(rotatedX + target.position.x, rotatedY + target.position.y, rotatedZ + target.position.z)
        }
        
        target.eulerAngles = SCNVector3(pitch,yaw,roll)

        //add sphere for every corner in the scene
        for (key, position) in corners {
            let node = SCNNode()
            node.name = key
            node.position = position
            node.geometry = SCNBox(width: 0.01, height: 0.01, length: 0.01, chamferRadius: 0)
            node.geometry?.firstMaterial?.diffuse.contents = UIColor.init(hue: 216/360, saturation: 68/100, brightness: 38/100, alpha: 1.0)
            node.rotation = target.rotation
            
            DispatchQueue.main.async {
                self.currentScene?.drawingNode.addChildNode(node)
            }
        }
        
    }
    
    ///updates the boundingBox position of the nodes which is currently visualized
    /**
        searches for the nodes of the bounding box and updates their position
     */
    func updateBoundingBox(_ target: ARPGeomNode) {
        
        let pitch = target.eulerAngles.x
        let yaw = target.eulerAngles.y
        let roll = target.eulerAngles.z
            
        target.eulerAngles = SCNVector3(0,0,0)
        
        let rfu = target.convertPosition(target.boundingBox.max, to: self.currentScene?.drawingNode)
        let lbd = target.convertPosition(target.boundingBox.min, to: self.currentScene?.drawingNode)
        
        let height = rfu.y - lbd.y
        let width = rfu.x - lbd.x
        
        let rbd = lbd + SCNVector3(x: width, y: 0, z: 0)
        let lbu = lbd + SCNVector3(x: 0, y: height, z: 0)
        let rbu = lbu + SCNVector3(x: width, y: 0, z: 0)
        
        let rfd = rfu - SCNVector3(x: 0, y: height, z: 0)
        let lfu = rfu - SCNVector3(x: width, y: 0, z: 0)
        let lfd = lfu - SCNVector3(x: 0, y: height, z: 0)
        
        var corners: [String: SCNVector3] = ["lbd": lbd, "rbd": rbd, "lbu": lbu, "rbu": rbu, "lfd": lfd, "rfd": rfd, "lfu": lfu, "rfu": rfu]
        
        for (key , position) in corners {
            
            let tempPos = position - target.position
            
            let rotatedX = (cos(roll)*cos(yaw))*tempPos.x + (cos(roll)*sin(yaw)*sin(pitch)-sin(roll)*cos(pitch))*tempPos.y + (cos(roll)*sin(yaw)*cos(pitch)+sin(roll)*sin(pitch))*tempPos.z
            let rotatedY = (sin(roll)*cos(yaw))*tempPos.x + (sin(roll)*sin(yaw)*sin(pitch)+cos(roll)*cos(pitch))*tempPos.y + (sin(roll)*sin(yaw)*cos(pitch)-cos(roll)*sin(pitch))*tempPos.z
            let rotatedZ = (-sin(yaw))*tempPos.x + (cos(yaw)*sin(pitch))*tempPos.y + (cos(yaw)*cos(pitch))*tempPos.z
            
            corners[key] = SCNVector3(rotatedX + target.position.x, rotatedY + target.position.y, rotatedZ + target.position.z)
        }
        
        self.currentScene?.drawingNode.childNode(withName: "lbd", recursively: true)?.position = corners["lbd"]!
        
        self.currentScene?.drawingNode.childNode(withName: "rfu", recursively: true)?.position = corners["rfu"]!
            
        self.currentScene?.drawingNode.childNode(withName: "rbd", recursively: true)?.position = corners["rbd"]!
            
        self.currentScene?.drawingNode.childNode(withName: "lbu", recursively: true)?.position = corners["lbu"]!
            
        self.currentScene?.drawingNode.childNode(withName: "rbu", recursively: true)?.position = corners["rbu"]!
    
        self.currentScene?.drawingNode.childNode(withName: "rfd", recursively: true)?.position = corners["rfd"]!
    
        self.currentScene?.drawingNode.childNode(withName: "lfu", recursively: true)?.position = corners["lfu"]!
            
        self.currentScene?.drawingNode.childNode(withName: "lfd", recursively: true)?.position = corners["lfd"]!
        
        target.eulerAngles = SCNVector3(pitch,yaw,roll)
    }
    
    ///search the scene for the boundingBox corners and then remove them
    /**
        
     */
    func removeBoundingBox(){
        let namesOfNodes = ["lbd", "rfu", "rbd", "lbu", "rbu", "lfd", "rfd", "lfu"]
        
        for item in namesOfNodes {
            self.currentScene?.drawingNode.childNode(withName: item, recursively: true)?.removeFromParentNode()
        }
        
    }
    
    ///a hitTest for the geometry in the scene
    /**
        
     */
    func hitTest(pointerPosition: SCNVector3) -> ARPGeomNode? {
            guard let sceneView = self.currentView  else { return nil }
            let projectedPencilPosition = sceneView.projectPoint(pointerPosition)
            let projectedCGPoint = CGPoint(x: CGFloat(projectedPencilPosition.x), y: CGFloat(projectedPencilPosition.y))
            
            // Cast a ray from that position and find the first ARPenNode
            let hitResults = sceneView.hitTest(projectedCGPoint, options: [SCNHitTestOption.searchMode : SCNHitTestSearchMode.all.rawValue])
           
            return hitResults.filter( { $0.node != currentScene?.pencilPoint } ).first?.node.parent as? ARPGeomNode
    }
    
    ///a hit Test specifically for the corners of the bounding box. Returns the SCNNode node which is hit if it is a corner
    /**
        First projects the position onto the image Plane and then searches for a hit with an object. This is fundamental for PenRay.
     */
    func hitTestCorners(pointerPosition: SCNVector3) -> SCNNode? {
        guard let sceneView = self.currentView  else { return nil }
        let projectedPencilPosition = sceneView.projectPoint(pointerPosition)
        let projectedCGPoint = CGPoint(x: CGFloat(projectedPencilPosition.x), y: CGFloat(projectedPencilPosition.y))
    
        // Cast a ray from that position and find the first ARPenNode
        let hitResults = sceneView.hitTest(projectedCGPoint, options: [SCNHitTestOption.searchMode : SCNHitTestSearchMode.all.rawValue])
        
        let namesOfCorners = ["lbd", "rbd", "lbu", "rbu", "lfd", "rfd", "lfu", "rfu"]
        
        return hitResults.filter( { $0.node != currentScene?.pencilPoint && namesOfCorners.contains($0.node.name ?? "empty") }).first?.node as SCNNode?
        
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

    ///
    /**
        
     */
    func didDoubleClick(_ button: Button) {
       //empty on purpose
    }
     
    ///
    /**
        
     */
    func visitTarget(_ target: ARPGeomNode) {
        unselectTarget(target)
        target.visited = true
        visitTarget = target
    }
    
    ///
    /**
        
     */
    func leaveTarget() {
        if let target = visitTarget {
            target.visited = false
            if let parent = target.parent?.parent as? ARPGeomNode {
                parent.visited = true
                visitTarget = parent
            } else {
                visitTarget = nil
            }
        }
    }
    
    ///
    /**
        
     */
    func unselectTarget(_ target: ARPGeomNode) {
        target.selected = false
        target.applyTransform()
        geometrySelected = false
        selectedTargets.removeAll(where: { $0 === target })
        removeBoundingBox()
        target.name = "generic"
    }
    
    ///
    /**
        
     */
    func selectTarget(_ target: ARPGeomNode) {
        if selectedTargets.count != 1 {
            geometrySelected = true
            target.selected = true
            target.name = "selected"
            selectedTargets.append(target)
            didSelectSomething?(target)
            target.applyTransform()
            viewBoundingBox(target)
        }
    }
    
}

extension PinchScaler : UndoRedoManagerNotifier{
    func actionUndone(_ manager: UndoRedoManager)
    {
        if self.active == true {
            prevRecScaleByOCCTRef.updateValue(prevRecScaleByOCCTRef[selectedTargets.first!.occtReference!]! - CGFloat(diffInScale!.x), forKey: selectedTargets.first!.occtReference!)
            if selectedTargets.count == 1{
                self.updateBoundingBox(selectedTargets.first!)
            }
        }
    }
    
    func actionRedone(_ manager: UndoRedoManager)
    {
        if self.active == true {
            if prevRecScaleByOCCTRef.count != 0 {
                prevRecScaleByOCCTRef.updateValue(prevRecScaleByOCCTRef[selectedTargets.first!.occtReference!]! + CGFloat(diffInScale!.x), forKey: selectedTargets.first!.occtReference!)
            }
            if selectedTargets.count == 1{
                self.updateBoundingBox(selectedTargets.first!)
            }
        }
    }
    
}
