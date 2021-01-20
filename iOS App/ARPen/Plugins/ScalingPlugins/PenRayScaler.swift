//
//  PenRayScaler.swift
//  ARPen
//
//  Created by Andreas RF Dymek on 29.11.20.
//  Copyright © 2020 RWTH Aachen. All rights reserved.
//
import Foundation
import ARKit

/**
This class handles the  selecting of meshes. When one mesh is selected the boundingBox corners are also visualized. We hover over corners and then select them using the PenRayScaling Plugin. Scaling then happens in the update method.
 
 Scaling is supporred for one selected mesh. Mulitple selection is not possible.
*/
class PenRayScaler {
    
    var currentScene: PenScene?
    var currentView: ARSCNView?
    var urManager: UndoRedoManager?
    
    private var buttonEvents: ButtonEvents
    private var lastClickPosition: SCNVector3?
    public var lastClickTime: Date?
    private var lastPenPosition: SCNVector3?
    
    //everything needed for undo/redo
    var initialScale: SCNVector3?
    var updatedScale: SCNVector3?
    var diagonalNodeBefore: SCNNode?
    var active: Bool?
    var pivotInCenter: Bool?
    var centerPosBefore: SCNVector3?
    
    /// The time (in seconds) after which holding the main button on an object results in dragging it.
    let timeTillDrag: Double = 0.15
    /// The minimum distance to move the pen starting at an object while holding the main button which results in dragging it.
    static let maxDistanceTillDrag: Float = 0.015
    /// Move the object with its center to the pen tip when dragging starts.
    static let snapWhenDragging: Bool = true
   
    ///original Height of the mesh when instantiated. Used for calculating scaleFactor for corner scaling
    var originalDiagonalLength: [String: Float] = [:]
    ///original Scale of the mesh when instantiated. If scale is not SCNVector3(1,1,1) this is necessary for accurate calculations
    ///since we only look at uniform scaling we store the x value of the SCNVector3
    var originalScale: [String: Float] = [:]
    
    
 
    ///the corner the pencilPoint hovers over
    var hoverCorner: SCNNode?
 
    var dragging: Bool = false
    
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
    var didSelectSomething: ((ARPGeomNode) -> Void)?
    private var geometrySelected = false

    init() {
        buttonEvents = ButtonEvents()
        buttonEvents.didPressButton = self.didPressButton
        buttonEvents.didReleaseButton = self.didReleaseButton
        buttonEvents.didDoubleClick = self.didDoubleClick
    }

    ///
    /**
        
     */
    func activate(withScene scene: PenScene, andView view: ARSCNView, urManager: UndoRedoManager) {
        self.currentView = view
        self.currentScene = scene
        self.urManager = urManager
        self.urManager?.notifier = self
        self.active = true
        self.dragging = false
        self.lastClickPosition = nil
        self.lastClickTime = nil
        self.lastPenPosition = nil
        
    }

    ///
    /**
        
     */
    func deactivate() {
        self.active = false
        for target in selectedTargets {
            unselectTarget(target)
        }
    }
    
    ///
    /**
        
     */
    func isPivotLocatedInCenter(target: ARPGeomNode) -> Bool {
        
        let center = target.convertPosition(target.geometryNode.boundingSphere.center, to: self.currentScene?.drawingNode)

        let worldTransf = SCNVector3(target.worldTransform.m41, target.worldTransform.m42, target.worldTransform.m43)
        
        return SCNVector3EqualToVector3(center, worldTransf)
    }
  
    ///gets executed each frame and is mainly responsible for scaling
    /**
        
     */
    func update(scene: PenScene, buttons: [Button : Bool]) {
             
        //check for button press
        buttonEvents.update(buttons: buttons)
        
        //for highlighting geometry the pencil point is over
        if selectedTargets.count != 1 {
            //check whether or not you hover over created geometry
            if let hit = hitTest(pointerPosition: scene.pencilPoint.position) {
                hoverTarget = hit
                
                
            } else {
                hoverTarget = nil
            }
        }
        
        //a geometry is selected
        if selectedTargets.count == 1
        {
            let namesOfCorners = ["lbd", "rbd", "lbu", "rbu", "lfd", "rfd", "lfu", "rfu"]
            
            //check for hit
            let cornerHit = hitTestCorners(pointerPosition: scene.pencilPoint.position)
                
            //CASE: A corner is hit
            if cornerHit != nil
            {
                //if corner is not being dragged, update the hover Corner
                if dragging == false
                {
                    hoverCorner = cornerHit
                    
                    hoverCorner!.geometry?.firstMaterial?.diffuse.contents = UIColor.red
                        
                    for item in namesOfCorners {
                        if(item != hoverCorner!.name ?? "empty"){
                            self.currentScene?.drawingNode.childNode(withName: item, recursively: true)?.geometry?.firstMaterial?.diffuse.contents = UIColor.init(red: 149/255, green: 31/255, blue: 163/255, alpha: 1.0)
                        }
                    }
                }
            }
    
            //Corner Scaling
            if (buttons[.Button2] ?? false) && ((Date() - (lastClickTime ?? Date())) > timeTillDrag) && hoverCorner != nil
            {
                dragging = true
                                
                hoverCorner?.geometry?.firstMaterial?.diffuse.contents = UIColor.red
                                    
                let diagonalNode = getDiagonalNode(selectedCorner: hoverCorner!)
                                    
                diagonalNode?.geometry?.firstMaterial?.diffuse.contents = UIColor.red
                    
                
                //we project onto the diagonal between the nodes on the imagePlane to avoid the visual offset of an orthogonal projection in 3d - with this method the corner will directly lay behind the pencilpoint
                let proj = projectOntoDiagonalIP(pencilPoint: scene.pencilPoint.position, selectedCorner: hoverCorner!.position, diagonal: diagonalNode!.position)
                       
                hoverCorner?.position = (self.currentView?.unprojectPoint(proj))!
                 
                let updatedDiagonal = hoverCorner!.position - diagonalNode!.position
                let updatedDiagonalLength = abs(updatedDiagonal.length())
          
                var scaleFactor = Float(updatedDiagonalLength / originalDiagonalLength[selectedTargets.first!.occtReference!]!)
                    
                //when the mesh was first selected, it did not have the scale of 1,1,1
                if (originalScale[selectedTargets.first!.occtReference!] != 1){
                    scaleFactor = originalScale[selectedTargets.first!.occtReference!]! * scaleFactor
                }
                        
                if scaleFactor < 0.2 {
                    scaleFactor = 0.2
                }

                diagonalNodeBefore = diagonalNode
                let before = diagonalNode?.position
                selectedTargets.first!.scale = SCNVector3(scaleFactor, scaleFactor, scaleFactor)
                                    
                self.updateBoundingBox(selectedTargets.first!)
                let after = getDiagonalNode(selectedCorner: hoverCorner!)?.position
                                 
                let x_of_diff = before!.x - after!.x
                let y_of_diff = before!.y - after!.y
                let z_of_diff = before!.z - after!.z
                let diff = SCNVector3(x: x_of_diff, y: y_of_diff, z: z_of_diff)
                selectedTargets.first!.position += diff
                self.updateBoundingBox(selectedTargets.first!)
                
            }
                
            //center scaling
            if (buttons[.Button3] ?? false && ((Date() - (lastClickTime ?? Date())) > timeTillDrag) && hoverCorner != nil)
            {
                    dragging = true
                           
                    for item in namesOfCorners {
                        self.currentScene?.drawingNode.childNode(withName: item, recursively: true)?.geometry?.firstMaterial?.diffuse.contents = UIColor.red
                    }
                        
                    let diagonalNode = getDiagonalNode(selectedCorner: hoverCorner!)
  
                   
                    let proj = projectOntoDiagonalIP(pencilPoint: scene.pencilPoint.position, selectedCorner: hoverCorner!.position, diagonal: diagonalNode!.position)
                       
                    hoverCorner?.position = (self.currentView?.unprojectPoint(proj))!
                        
                    let updatedDiagonal = hoverCorner!.position - diagonalNode!.position
                    let updatedDiagonalLength = abs(updatedDiagonal.length())
                                    
                    var scaleFactor = Float(updatedDiagonalLength / originalDiagonalLength[selectedTargets.first!.occtReference!]!)
                        
                    //when the mesh was first selected, it did not have the scale of 1,1,1
                    if (originalScale[selectedTargets.first!.occtReference!] != 1){
                            scaleFactor = originalScale[selectedTargets.first!.occtReference!]! * scaleFactor
                    }
                        
                    if scaleFactor < 0.3 {
                        scaleFactor = 0.3
                    }
                        
                    pivotInCenter = isPivotLocatedInCenter(target: selectedTargets.first!)
                        
                    centerPosBefore = selectedTargets.first!.convertPosition(selectedTargets.first!.geometryNode.boundingSphere.center, to: self.currentScene?.drawingNode)
                                    
                    selectedTargets.first!.scale = SCNVector3(scaleFactor, scaleFactor, scaleFactor)

                    self.updateBoundingBox(selectedTargets.first!)
                                    
                    let centerAfter = selectedTargets.first!.convertPosition(selectedTargets.first!.geometryNode.boundingSphere.center, to: self.currentScene?.drawingNode)

                    let diff = centerPosBefore! - centerAfter
            
                    selectedTargets.first!.position += diff
             
                    self.updateBoundingBox(selectedTargets.first!)
                    
            }

            if dragging == false && cornerHit == nil {
                for item in namesOfCorners {
                    self.currentScene?.drawingNode.childNode(withName: item, recursively: true)?.geometry?.firstMaterial?.diffuse.contents = UIColor.init(red: 149/255, green: 31/255, blue: 163/255, alpha: 1.0)
                }
            }

        }
    }
    
    ///projects the pencilPoint on a given diagonal on the image plane
    /**
           
    */
    func projectOntoDiagonalIP(pencilPoint: SCNVector3, selectedCorner: SCNVector3, diagonal: SCNVector3) -> SCNVector3 {
        
        let projP = self.currentView?.projectPoint(pencilPoint)
        let projS = self.currentView?.projectPoint(selectedCorner)
        let projD = self.currentView?.projectPoint(diagonal)
        
        let DS = CGPoint(x: Double(projS!.x - projD!.x), y: Double(projS!.y - projD!.y))
               
        let DP = CGPoint(x: Double(projP!.x - projD!.x), y: Double(projP!.y - projD!.y))
               
        let scalar = (dotProduct(DP, DS) / dotProduct(DS, DS))
               
        let scalarDS = CGPoint(x: DS.x * scalar, y: DS.y * scalar)
               
        let ret = CGPoint(x: Double(projD!.x), y: Double(projD!.y)) + scalarDS
        
        return SCNVector3(x: Float(ret.x), y: Float(ret.y), z: Float(projS!.z))
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
    func didPressButton(_ button: Button) {
        
        switch button {
        
        case .Button1:
            if let target = hoverTarget {
                if !selectedTargets.contains(target) {
                    selectTarget(target)
                }
            } else {
                for target in selectedTargets {
                    unselectTarget(target)
                }
            }
        
        case .Button2, .Button3:
            lastClickPosition = currentScene?.pencilPoint.position
            lastPenPosition = currentScene?.pencilPoint.position
            lastClickTime = Date()
            initialScale = selectedTargets.first?.scale

        }
    }
    
    ///
    /**
           
    */
    func didReleaseButton(_ button: Button) {
        switch button {
        case .Button1:
           
            if let target = hoverTarget, !geometrySelected {
                if selectedTargets.contains(target) {
                    unselectTarget(target)
                }
            }
            
            geometrySelected = false
        
        case .Button2:
            hoverCorner = nil
            if dragging
            {
                DispatchQueue.global(qos: .userInitiated).async {
                    // Do this in the background, as it may cause a time-intensive rebuild in the parent object
                    self.selectedTargets.first!.applyTransform()
                }
            }
            dragging = false
            
            if selectedTargets.count == 1 {
                if diagonalNodeBefore != nil {
                    updatedScale = selectedTargets.first?.scale
                    let diffInScale =  updatedScale! - initialScale!
                    let scalingAction = CornerScalingAction(occtRef: selectedTargets.first!.occtReference!, scene: self.currentScene!, diffInScale: diffInScale, diagonalNodeBefore: diagonalNodeBefore!)
                    self.urManager?.actionDone(scalingAction)
                }
            }
            
        case .Button3:
            hoverCorner = nil
            if dragging
            {
                DispatchQueue.global(qos: .userInitiated).async {
                    // Do this in the background, as it may cause a time-intensive rebuild in the parent object
                    self.selectedTargets.first!.applyTransform()
                }
                
            }
            dragging = false
            
            if selectedTargets.count == 1 {
                if centerPosBefore != nil && pivotInCenter != nil {
 
                    updatedScale = selectedTargets.first?.scale
                    let diffInScale =  updatedScale! - initialScale!
                    
                    let scalingAction = CenterScalingAction(occtRef: selectedTargets.first!.occtReference!, scene: self.currentScene!, diffInScale: diffInScale, centerBefore: centerPosBefore!, pivotCentered: pivotInCenter!)
          
                    self.urManager?.actionDone(scalingAction)
                }
            }
            
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
            
        let ref = target.occtReference
        
        //mincorner of bounding box
        let lbd = target.convertPosition(target.boundingBox.min, to: self.currentScene?.drawingNode)
        
        //maxcorner of bounding box
        let rfu = target.convertPosition(target.boundingBox.max, to: self.currentScene?.drawingNode)
     
        let diagonal = rfu - lbd
        let diagonalLength = abs(diagonal.length())
        
        //first time we selected geometry so store new value
        if !(originalDiagonalLength.keys.contains(ref!)){
            originalDiagonalLength.updateValue(diagonalLength, forKey: ref!)
        }
        
        //first time we selected geometry, so we need to store scale to later check for non-1 scale
        if !(originalScale.keys.contains(ref!)){
            originalScale.updateValue(target.scale.x, forKey: ref!)
        }
        
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
            node.geometry = SCNSphere(radius: 0.008)
            node.geometry?.firstMaterial?.diffuse.contents = UIColor.init(red: 149/255, green: 31/255, blue: 163/255, alpha: 1.0)
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
            self.currentScene?.drawingNode.childNode(withName: key, recursively: true)?.position = corners[key]!
        }
        
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
    
    ///
    /**
        
     */
    func unselectTarget(_ target: ARPGeomNode) {
        target.selected = false
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
    
    ///
    /**
           
    */
    func didDoubleClick(_ button: Button) {
        //empty on purpose
    }
}

extension PenRayScaler : UndoRedoManagerNotifier{
    func actionUndone(_ manager: UndoRedoManager)
    {
        if self.active == true {
            if selectedTargets.count == 1{
                for target in selectedTargets {
                    unselectTarget(target)
                }
                self.removeBoundingBox()
            }
        }
    }
    
    func actionRedone(_ manager: UndoRedoManager)
    {
        if self.active == true {
            if selectedTargets.count == 1{
                for target in selectedTargets {
                    unselectTarget(target)
                }
                self.removeBoundingBox()
            }
        }
    }
    
}
