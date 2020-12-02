//
//  Scaler.swift
//  ARPen
//
//  Created by Andreas RF Dymek on 29.11.20.
//  Copyright © 2020 RWTH Aachen. All rights reserved.
//

import Foundation
import ARKit

/**
This class handles the selecting and arranging and "visiting" of objects, as this functionality is shared across multiple plugins. An examplary usage can be seen in `CombinePluginTutorial.swift`.
To "visit" means to march down the hierarchy of a node, e.g. to rearrange the object which form a Boolean operation.
*/
class Scaler {
    
    var currentScene: PenScene?
    var currentView: ARSCNView?
    
    /// The time (in seconds) after which holding the main button on an object results in dragging it.
    static let timeTillDrag: Double = 1
    /// The minimum distance to move the pen starting at an object while holding the main button which results in dragging it.
    static let maxDistanceTillDrag: Float = 0.015
    /// Move the object with its center to the pen tip when dragging starts.
    static let snapWhenDragging: Bool = true
    
    ///original Height of the mesh when instantiated. Used for calculating scaleFactor
    var originalMeshHeight: Float?
    var originalMeshWidth: Float?
    var originalMeshLength: Float?
    
    ///the currently selected corner of the meshes bounding box
    var selectedCorner: SCNNode?
    ///boolean which indicates if a corner is currently selected
    var isACornerSelected: Bool = false
    
    
    //hoverTarget uses didSet to update any dependency automatically
    var hoverTarget: ARPNode? {
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
    var selectedTargets: [ARPNode] = []

    var visitTarget: ARPGeomNode?
    var dragging: Bool = false
    private var buttonEvents: ButtonEvents
    private var justSelectedSomething = false
    
    private var lastClickPosition: SCNVector3?
    private var lastClickTime: Date?
    private var lastPenPosition: SCNVector3?
    
    var didSelectSomething: ((ARPNode) -> Void)?
    
    init() {
        buttonEvents = ButtonEvents()
        buttonEvents.didPressButton = self.didPressButton
        buttonEvents.didReleaseButton = self.didReleaseButton
        buttonEvents.didDoubleClick = self.didDoubleClick
    }

    func activate(withScene scene: PenScene, andView view: ARSCNView) {
        self.currentView = view
        self.currentScene = scene
        self.visitTarget = nil
        self.dragging = false
        self.justSelectedSomething = false
        self.lastClickPosition = nil
        self.lastClickTime = nil
        self.lastPenPosition = nil
    }


    func deactivate() {
        for target in selectedTargets {
            unselectTarget(target)
        }
    }
    
    //here the actual scaling happens
    func update(scene: PenScene, buttons: [Button : Bool]) {
        
        buttonEvents.update(buttons: buttons)
       
        if let hit = hitTest(pointerPosition: scene.pencilPoint.position) {
            hoverTarget = hit
        } else {
            hoverTarget = nil
        }
        
        //a target is selected and a bounding box is visible
        if selectedTargets.count == 1 {

            let cornerHit = hitTestCorners(pointerPosition: scene.pencilPoint.position)
            
            let namesOfCorners = ["lbd", "rbd", "lbu", "rbu", "lfd", "rfd", "lfu", "rfu"]
            
            //a corner is hit
            if namesOfCorners.contains(cornerHit?.name ?? "empty"){
                
                if(isACornerSelected == false){
                    cornerHit?.geometry?.firstMaterial?.diffuse.contents = UIColor.systemPink
                }
                
                let pressed2 = buttons[Button.Button2]!
                
                if pressed2 {
                    if (isACornerSelected == false){
                        selectedCorner = cornerHit!
                        cornerHit?.geometry?.firstMaterial?.diffuse.contents = UIColor.systemYellow
                        isACornerSelected = true
                    }
                    
                    else {
                        if(cornerHit! == selectedCorner){
                            selectedCorner = SCNNode()
                            selectedCorner!.name = "generic"
                            isACornerSelected = false
                        }
                    }
                }

            }
            
            //no corner is hit
            else {
                for item in namesOfCorners {
                    if(item != selectedCorner?.name ?? "empty"){
                        self.currentScene?.drawingNode.childNode(withName: item, recursively: true)?.geometry?.firstMaterial?.diffuse.contents = UIColor.systemGreen
                    }
                }
            }
            
            //a corner is selected and we can start scaling
            if(isACornerSelected == true)
            {
                let pressed = buttons[Button.Button3]!
                 
                if pressed {
                    
                   // let selected = selectedTargets.first as? ARPGeomNode
                   // let scnGeometry = OCCTAPI().occt.sceneKitMesh(of: selected?.occtReference)
               
                    
                    let diagonalNode = getDiagonalNode(selectedCorner: selectedCorner!)
                    let before = diagonalNode?.position
                    

                    
                    let updatedMeshHeight = abs(scene.pencilPoint.position.y - (diagonalNode?.position.y)!)
                    let scaleFactor = Float(updatedMeshHeight / originalMeshHeight!)
                    
                    
                    selectedTargets.first!.scale = SCNVector3(x: scaleFactor, y: scaleFactor, z: scaleFactor)
                    reinstatiateBoundingBox(selectedTargets.first!)
                    
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
                    
                    reinstatiateBoundingBox(selectedTargets.first!)
                    
                    if !pressed{
                        selectedTargets.first?.applyTransform()
                    }
                }
                
            }
        }
    }
    

    func projectOntoDiagonal(pencilPoint: CGPoint, screenCorner: CGPoint, dirVector: CGPoint) -> CGPoint {
        let vecA = CGPoint(x: pencilPoint.x - screenCorner.x, y: pencilPoint.y - screenCorner.y)
        let scalar1 = dotProduct(vecA: vecA, vecB: dirVector) / dotProduct(vecA: dirVector, vecB: dirVector)
        let scalarDirVector = CGPoint(x: dirVector.x * scalar1, y: dirVector.y * scalar1)
        let projectedPoint1 = CGPoint(x: screenCorner.x + scalarDirVector.x, y: screenCorner.y + scalarDirVector.y)
        return projectedPoint1
    }
    

    func getProjectedDiagonal(selectedCorner: SCNNode) -> CGPoint {
        
        let name = selectedCorner.name
    
        if(name == "lbd" || name == "rfu"){
            let lower = projectOntoImagePlane(pointerPosition: (self.currentScene?.drawingNode.childNode(withName: "lbd", recursively: true)!.position)!)
            let higher = projectOntoImagePlane(pointerPosition: (self.currentScene?.drawingNode.childNode(withName: "rfu", recursively: true)!.position)!)
            
            return CGPoint(x: lower!.x - higher!.x, y: lower!.y - higher!.y)
        }
        
        if(name == "rbd" || name == "lfu"){
            let lower = projectOntoImagePlane(pointerPosition: (self.currentScene?.drawingNode.childNode(withName: "rbd", recursively: true)!.position)!)
            let higher = projectOntoImagePlane(pointerPosition: (self.currentScene?.drawingNode.childNode(withName: "lfu", recursively: true)!.position)!)
            
            return CGPoint(x: lower!.x - higher!.x, y: lower!.y - higher!.y)
        }
        
        if(name == "lfd" || name == "rbu"){
            let lower = projectOntoImagePlane(pointerPosition: (self.currentScene?.drawingNode.childNode(withName: "lfd", recursively: true)!.position)!)
            let higher = projectOntoImagePlane(pointerPosition: (self.currentScene?.drawingNode.childNode(withName: "rbu", recursively: true)!.position)!)
            
            return CGPoint(x: lower!.x - higher!.x, y: lower!.y - higher!.y)
        }
        
        if(name == "rfd" || name == "lbu"){
            let lower = projectOntoImagePlane(pointerPosition: (self.currentScene?.drawingNode.childNode(withName: "rfd", recursively: true)!.position)!)
            let higher = projectOntoImagePlane(pointerPosition: (self.currentScene?.drawingNode.childNode(withName: "lbu", recursively: true)!.position)!)
            
            return CGPoint(x: lower!.x - higher!.x, y: lower!.y - higher!.y)
        }
        
        //just in case
        return CGPoint(x: 0, y: 0)
    }
        
    func getDiagonalNode(selectedCorner: SCNNode) -> SCNNode? {
        
        let name = selectedCorner.name
        
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
        
        if(name == "rfu")
        {
            return self.currentScene?.drawingNode.childNode(withName: "lbd", recursively: true)
        }
        
        if(name == "lbd")
        {
            return self.currentScene?.drawingNode.childNode(withName: "rfu", recursively: true)
        }
        
        return nil
    }
        
    ///reinstantiates the bounding box  of a given target
    /**
        searches the scene for the bounding box nodes and updates their new position given by the update method
     */
    func reinstatiateBoundingBox(_ target: ARPNode) {
        self.currentScene?.drawingNode.childNode(withName: "lbd", recursively: true)?.position = target.convertPosition(target.boundingBox.min, to: self.currentScene?.drawingNode)
        self.currentScene?.drawingNode.childNode(withName: "rfu", recursively: true)?.position = target.convertPosition(target.boundingBox.max, to: self.currentScene?.drawingNode)
        
        
        let height = (self.currentScene?.drawingNode.childNode(withName: "rfu", recursively: true)?.position.y)! - (self.currentScene?.drawingNode.childNode(withName: "lbd", recursively: true)?.position.y)!
        originalMeshHeight = height
        
        let width = (self.currentScene?.drawingNode.childNode(withName: "rfu", recursively: true)?.position.x)! - (self.currentScene?.drawingNode.childNode(withName: "lbd", recursively: true)?.position.x)!
        originalMeshWidth = width
        
        let length = (self.currentScene?.drawingNode.childNode(withName: "rfu", recursively: true)?.position.z)! - (self.currentScene?.drawingNode.childNode(withName: "lbd", recursively: true)?.position.z)!
        originalMeshLength = length
        
        
        self.currentScene?.drawingNode.childNode(withName: "rbd", recursively: true)?.position = (self.currentScene?.drawingNode.childNode(withName: "lbd", recursively: true)!.position)! + SCNVector3(x: width, y: 0, z: 0)
        
        self.currentScene?.drawingNode.childNode(withName: "lbu", recursively: true)?.position = (self.currentScene?.drawingNode.childNode(withName: "lbd", recursively: true)!.position)! + SCNVector3(x: 0, y: height, z: 0)
        
        self.currentScene?.drawingNode.childNode(withName: "rbu", recursively: true)?.position = (self.currentScene?.drawingNode.childNode(withName: "lbu", recursively: true)!.position)! + SCNVector3(x: width, y: 0, z: 0)
        
        self.currentScene?.drawingNode.childNode(withName: "rfd", recursively: true)?.position = (self.currentScene?.drawingNode.childNode(withName: "rfu", recursively: true)!.position)! - SCNVector3(x: 0, y: height, z: 0)
        
        self.currentScene?.drawingNode.childNode(withName: "lfu", recursively: true)?.position = (self.currentScene?.drawingNode.childNode(withName: "rfu", recursively: true)!.position)! - SCNVector3(x: width, y: 0, z: 0)
        
        self.currentScene?.drawingNode.childNode(withName: "lfd", recursively: true)?.position = (self.currentScene?.drawingNode.childNode(withName: "lfu", recursively: true)!.position)! - SCNVector3(x: 0, y: height, z: 0)

    }

    ///visualize the bounding box  of a given target
    /**
       uses calcNodesBoundingBox() to acquire corners. Then proceeds to visualize them and lines in between the nodes. Result is a visualization of the boundingBox of the selected Mesh.
     */
    func viewBoundingBox(_ target: ARPNode) {
        
        //get all 8 corners of the bounding box
        let corners = calcNodesBoundingBox(target)
        
        //add sphere for every corner in the scene
        for (key, position) in corners {
            let node = SCNNode()
            node.name = key
            node.position = position
            node.geometry = SCNBox(width: 0.01, height: 0.01, length: 0.01, chamferRadius: 0)
            node.geometry?.firstMaterial?.diffuse.contents = UIColor.systemGreen
                
            DispatchQueue.main.async {
                self.currentScene?.drawingNode.addChildNode(node)
            }
        }
        /*
        lineBetweenNodes(positionA: corners["lbd"]!, positionB: corners["rbd"]!, name: "lbd_to_rbd")
        lineBetweenNodes(positionA: corners["lbd"]!, positionB: corners["lbu"]!, name: "lbd_to_lbu")
        lineBetweenNodes(positionA: corners["lbd"]!, positionB: corners["lfd"]!, name: "lbd_to_lfd")
        lineBetweenNodes(positionA: corners["lbu"]!, positionB: corners["rbu"]!, name: "lbu_to_rbu")
        lineBetweenNodes(positionA: corners["lbu"]!, positionB: corners["lfu"]!, name: "lbu_to_lfu")
        lineBetweenNodes(positionA: corners["rbd"]!, positionB: corners["rbu"]!, name: "rbd_to_rbu")
        lineBetweenNodes(positionA: corners["rbd"]!, positionB: corners["rfd"]!, name: "rbd_to_rfd")
        lineBetweenNodes(positionA: corners["rbu"]!, positionB: corners["rfu"]!, name: "rbu_to_rfu")
        lineBetweenNodes(positionA: corners["lfd"]!, positionB: corners["lfu"]!, name: "lfd_to_lfu")
        lineBetweenNodes(positionA: corners["lfd"]!, positionB: corners["rfd"]!, name: "lfd_to_rfd")
        lineBetweenNodes(positionA: corners["rfu"]!, positionB: corners["lfu"]!, name: "rfu_to_lfu")
        lineBetweenNodes(positionA: corners["rfu"]!, positionB: corners["rfd"]!, name: "rfu_to_rfd")*/
        
    }
    
    ///returns all 8 bounding box corners in world coordinates of a given target as a dictionary. Identify corners in the dictionary via keys in format of "lbd" = left bottom down / "rfu" = right front up
    /**
       returns the corners as a dictionary. Keys are in the format, e.g. "lbd" or "rfu"
       l = left , r = right , b = back , f = front , d = down , u = up
     */
    func calcNodesBoundingBox(_ target: ARPNode) -> [String: SCNVector3] {
        
        //mincorner of bounding box
        let lbd = target.convertPosition(target.boundingBox.min, to: self.currentScene?.drawingNode)
        
        //maxcorner of bounding box
        let rfu = target.convertPosition(target.boundingBox.max, to: self.currentScene?.drawingNode)
        
        //Determine height and width of bounding box
        let height = rfu.y - lbd.y
        originalMeshHeight = height
        
        let width = rfu.x - lbd.x
        originalMeshWidth = width
        
        let length = rfu.z - lbd.z
        originalMeshLength = length
        
        let rbd = lbd + SCNVector3(x: width, y: 0, z: 0)
        let lbu = lbd + SCNVector3(x: 0, y: height, z: 0)
        let rbu = lbu + SCNVector3(x: width, y: 0, z: 0)
        
        let rfd = rfu - SCNVector3(x: 0, y: height, z: 0)
        let lfu = rfu - SCNVector3(x: width, y: 0, z: 0)
        let lfd = lfu - SCNVector3(x: 0, y: height, z: 0)
        
        let nodes: [String: SCNVector3] = ["lbd": lbd, "rbd": rbd, "lbu": lbu, "rbu": rbu, "lfd": lfd, "rfd": rfd, "lfu": lfu, "rfu": rfu]

        return nodes
    }
    
    ///visualizes a line between two positions as a SCNCylinder
    /**
       draws a SCNCylinder between two given positions in form of two SCNVector3.
       inspired by Farhadiba Mohammed.
     */
    func lineBetweenNodes(positionA: SCNVector3, positionB: SCNVector3, name: String) {
        let vector = SCNVector3(positionA.x - positionB.x, positionA.y - positionB.y, positionA.z - positionB.z)
        let distance = sqrt(vector.x * vector.x + vector.y * vector.y + vector.z * vector.z)
        
        let midPosition = SCNVector3 (x:(positionA.x + positionB.x) / 2, y:(positionA.y + positionB.y) / 2, z:(positionA.z + positionB.z) / 2)

        let lineGeometry = SCNCylinder()
        lineGeometry.radius = 0.0004
        lineGeometry.height = CGFloat(distance)
        lineGeometry.radialSegmentCount = 5
        lineGeometry.firstMaterial!.diffuse.contents = UIColor.systemGreen

        let lineNode = SCNNode(geometry: lineGeometry)
        lineNode.name = name
        lineNode.opacity = 0.7
        lineNode.position = midPosition
        
        lineNode.look (at: positionB, up: (self.currentScene?.rootNode.worldUp)!, localFront: lineNode.worldUp)
        
        DispatchQueue.main.async {
            self.currentScene?.drawingNode.addChildNode(lineNode)
        }
  
    }
   
    func removeBoundingBox(){
        let namesOfNodes = ["lbd", "rbd", "lbu", "rbu", "lfd", "rfd", "lfu", "rfu"]
        
        for item in namesOfNodes {
            self.currentScene?.drawingNode.childNode(withName: item, recursively: true)?.removeFromParentNode()
        }
        
    }
    
    ///modified hitTest to only return if nodes of ARPen GeometryNodes are hit
    func hitTest(pointerPosition: SCNVector3) -> ARPNode? {
            guard let sceneView = self.currentView  else { return nil }
            let projectedPencilPosition = sceneView.projectPoint(pointerPosition)
            let projectedCGPoint = CGPoint(x: CGFloat(projectedPencilPosition.x), y: CGFloat(projectedPencilPosition.y))
            
            // Cast a ray from that position and find the first ARPenNode
            let hitResults = sceneView.hitTest(projectedCGPoint, options: [SCNHitTestOption.searchMode : SCNHitTestSearchMode.all.rawValue])
           
            return hitResults.filter( { $0.node != currentScene?.pencilPoint } ).first?.node.parent as? ARPNode
    }
    
    func hitTestCorners(pointerPosition: SCNVector3) -> SCNNode? {
        guard let sceneView = self.currentView  else { return nil }
        let projectedPencilPosition = sceneView.projectPoint(pointerPosition)
        let projectedCGPoint = CGPoint(x: CGFloat(projectedPencilPosition.x), y: CGFloat(projectedPencilPosition.y))
    
        // Cast a ray from that position and find the first ARPenNode
        let hitResults = sceneView.hitTest(projectedCGPoint, options: [SCNHitTestOption.searchMode : SCNHitTestSearchMode.all.rawValue])
        
        return hitResults.filter( { $0.node != currentScene?.pencilPoint} ).first?.node as SCNNode?
        
    }
    
    func projectOntoImagePlane(pointerPosition: SCNVector3) -> CGPoint? {
        guard let sceneView = self.currentView  else { return nil }
        let projectedPencilPosition = sceneView.projectPoint(pointerPosition)
        let projectedCGPoint = CGPoint(x: CGFloat(projectedPencilPosition.x), y: CGFloat(projectedPencilPosition.y))

        return projectedCGPoint
    }
    
    func dotProduct(vecA: CGPoint, vecB: CGPoint)-> CGFloat{
        return (vecA.x * vecB.x + vecA.y * vecB.y)
    }
    
    func didPressButton(_ button: Button) {
        
        switch button {
        
        case .Button1:
            lastClickPosition = currentScene?.pencilPoint.position
            lastPenPosition = currentScene?.pencilPoint.position
            lastClickTime = Date()
            
            if let target = hoverTarget {
                if !selectedTargets.contains(target) {
                    selectTarget(target)
                    
 
                    
                }
            } else {
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
            if dragging {
                for target in selectedTargets {
                    DispatchQueue.global(qos: .userInitiated).async {
                        // Do this in the background, as it may cause a time-intensive rebuild in the parent object
                        target.applyTransform()
                    }
                }
            } else {
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
       //empty on purpose
    }
    
    func visitTarget(_ target: ARPGeomNode) {
        unselectTarget(target)
        target.visited = true
        visitTarget = target
    }
    
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
    
    func unselectTarget(_ target: ARPNode) {
        target.selected = false
        selectedTargets.removeAll(where: { $0 === target })
        removeBoundingBox()
    }
    
    func selectTarget(_ target: ARPNode) {
        if selectedTargets.count != 1 {
            target.selected = true
            selectedTargets.append(target)
            justSelectedSomething = true
            didSelectSomething?(target)
            viewBoundingBox(target)
        }
    }
    
}
