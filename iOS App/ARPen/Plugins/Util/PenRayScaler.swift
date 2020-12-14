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
This class handles the "visiting" and selecting of meshes. When one mesh is selected the boundingBox corners are also visualized. We hover over corerns and then select them using the PenRayScaling Plugin. Scaling then happens in the update method.
 
 Scaling is supporred for one selected mesh. Mulitple selection is not possible.
 Some code was inspired by the work of Farhadiba Mohammed on ARPen.
*/
class PenRayScaler {
    
    var currentScene: PenScene?
    var currentView: ARSCNView?
  
    
    ///
    var rotationSave: SCNVector4?
    
    ///original Height of the mesh when instantiated. Used for calculating scaleFactor
    var originalMeshHeight: Float?
    ///the current scale Factor with which the mesh is scaled by
    var currentScaleFactor: Float?
    ///the currently selected corner of the meshes bounding box
    var selectedCorner: SCNNode?
    ///the corner the pencilPoint hovers over
    var hoverCorner: SCNNode?
    ///boolean which indicates if a corner is currently selected
    var isACornerSelected: Bool = false
    /// The time (in seconds) after which holding the main button on an object results in dragging it.
    let timeTillDrag: Double = 3
    /// The minimum distance to move the pen starting at an object while holding the main button which results in dragging it.
    static let maxDistanceTillDrag: Float = 0.015
    /// Move the object with its center to the pen tip when dragging starts.
    static let snapWhenDragging: Bool = true

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
    public var lastClickTime: Date?
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
    
    
    ///gets executed each frame and is responsible for scaling
    /**
        
     */
    func update(scene: PenScene, buttons: [Button : Bool]) {
        
        //check for button press
        buttonEvents.update(buttons: buttons)
       
        if selectedTargets.count != 1 {
            //check whether or not you hover over created geometry
            if let hit = hitTest(pointerPosition: scene.pencilPoint.position) {
                hoverTarget = hit
            } else {
                hoverTarget = nil
            }
        }
        
        //geometry was selected and bounding box is visible
        if selectedTargets.count == 1 {
            
            //check for hit
            let cornerHit = hitTestCorners(pointerPosition: scene.pencilPoint.position)
            let namesOfCorners = ["lbd", "rbd", "lbu", "rbu", "lfd", "rfd", "lfu", "rfu"]
            
            //A corner is hit - update hoverCorner and color corner
            if namesOfCorners.contains(cornerHit?.name ?? "empty"){
                if(isACornerSelected == false){
                    cornerHit?.geometry?.firstMaterial?.diffuse.contents = UIColor.init(hue: 216/360, saturation: 68/100, brightness: 98/100, alpha: 1.0)
                }
                hoverCorner = cornerHit
            }
            
            //No corner is hit - update color of every corner EXCEPT the selectedCorner
            else
            {
                for item in namesOfCorners {
                    if(item != selectedCorner?.name ?? "empty"){
                        self.currentScene?.drawingNode.childNode(withName: item, recursively: true)?.geometry?.firstMaterial?.diffuse.contents = UIColor.init(hue: 216/360, saturation: 68/100, brightness: 68/100, alpha: 1.0)
                    }
                }
                hoverCorner = nil
            }
            
            
            /**
                a corner is selected -> scaling starts
             */
            if(isACornerSelected == true)
            {
                
                var currentPoint: CGPoint
                
                let diagonalNode = getDiagonalNode(selectedCorner: selectedCorner!)
 
                let upper = ["lbu", "rbu", "lfu", "rfu"]
                
                //project the current pencil point onto the diagonal between the selected and its diagonal corner
                
                //the selected corner is an upper corner
                if(upper.contains((selectedCorner!.name)!)){
                    let pencilPointImagePlane = projectOntoImagePlane(pointerPosition: scene.pencilPoint.position)!
                    let currentCornerImagePlane = projectOntoImagePlane(pointerPosition: selectedCorner!.position)!
                    let diagonal = getProjectedDiagonal(selectedCorner: selectedCorner!)
                    currentPoint = projectOntoDiagonal(pencilPoint: pencilPointImagePlane, upperCorner: currentCornerImagePlane, diagonal: diagonal)
                }
                
                //the diagonal node is an upper corner
                else {
                    let pencilPointImagePlane = projectOntoImagePlane(pointerPosition: scene.pencilPoint.position)!
                    let diagonalImagePlane = projectOntoImagePlane(pointerPosition: diagonalNode!.position)
                    let diagonal = getProjectedDiagonal(selectedCorner: selectedCorner!)
                    currentPoint = projectOntoDiagonal(pencilPoint: pencilPointImagePlane, upperCorner: diagonalImagePlane!, diagonal: diagonal)
                  
                }
                
                //check for hitTest on the diagonal
                var hitTest = self.currentView!.hitTest(currentPoint, options: [SCNHitTestOption.searchMode : SCNHitTestSearchMode.all.rawValue] )
                
                hitTest = hitTest.filter({namesOfCorners.contains($0.node.name ?? "empty")})
                
                //for each hit with we scale hit.worldCoordinates.y
                for hit in hitTest {
                    
                    let diagonalNode = getDiagonalNode(selectedCorner: selectedCorner!)
                    let before = diagonalNode?.position

                    let updatedMeshHeight = abs(hit.worldCoordinates.y - (diagonalNode?.position.y)!)
                    let scaleFactor = Float(updatedMeshHeight / originalMeshHeight!)
                    currentScaleFactor = scaleFactor
                    
                    selectedTargets.first!.scale = SCNVector3(scaleFactor, scaleFactor, scaleFactor)
                    self.showBoundingBoxForGivenMesh(mesh: selectedTargets.first!)
                    
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
                    
                    self.showBoundingBoxForGivenMesh(mesh: selectedTargets.first!)
 
               }
            }
        }
    }
    
 
    ///updates the boundingBox position of the nodes which is currently visualized
    /**
        searches for the nodes of the bounding box and updates their position
     */
    func showBoundingBoxForGivenMesh(mesh: SCNNode) {
        let max = mesh.convertPosition(mesh.boundingBox.max, to: self.currentScene?.drawingNode)
        let min = mesh.convertPosition(mesh.boundingBox.min, to: self.currentScene?.drawingNode)
        
        let height = max.y - min.y
        let width = max.x - min.x
       
        self.currentScene?.drawingNode.childNode(withName: "lbd", recursively: true)?.position = min
        
        self.currentScene?.drawingNode.childNode(withName: "rfu", recursively: true)?.position = max
            
        self.currentScene?.drawingNode.childNode(withName: "rbd", recursively: true)?.position = (self.currentScene?.drawingNode.childNode(withName: "lbd", recursively: true)!.position)! + SCNVector3(x: width, y: 0, z: 0)
            
        self.currentScene?.drawingNode.childNode(withName: "lbu", recursively: true)?.position = (self.currentScene?.drawingNode.childNode(withName: "lbd", recursively: true)!.position)! + SCNVector3(x: 0, y: height, z: 0)
            
        self.currentScene?.drawingNode.childNode(withName: "rbu", recursively: true)?.position = (self.currentScene?.drawingNode.childNode(withName: "lbd", recursively: true)!.position)! + SCNVector3(x: width, y: height, z: 0)
            
        self.currentScene?.drawingNode.childNode(withName: "rfd", recursively: true)?.position = (self.currentScene?.drawingNode.childNode(withName: "rfu", recursively: true)!.position)! - SCNVector3(x: 0, y: height, z: 0)
            
        self.currentScene?.drawingNode.childNode(withName: "lfu", recursively: true)?.position = (self.currentScene?.drawingNode.childNode(withName: "rfu", recursively: true)!.position)! - SCNVector3(x: width, y: 0, z: 0)
            
        self.currentScene?.drawingNode.childNode(withName: "lfd", recursively: true)?.position = (self.currentScene?.drawingNode.childNode(withName: "rfu", recursively: true)!.position)! - SCNVector3(x: width, y: height, z: 0)
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
    
    ///visualize the bounding box  of a given target
    /**
       uses calcNodesBoundingBox() to acquire corners. Then proceeds to visualize them and lines in between the nodes. Result is a visualization of the boundingBox of the selected Mesh.
     */
    func viewBoundingBox(_ target: SCNNode) {
        
        //get all 8 corners of the bounding box
        let corners = calcNodesBoundingBox(target)
        
        //add sphere for every corner in the scene
        for (key, position) in corners {
            let node = SCNNode()
            node.name = key
            node.position = position
            node.geometry = SCNBox(width: 0.01, height: 0.01, length: 0.01, chamferRadius: 0)
            node.geometry?.firstMaterial?.diffuse.contents = UIColor.init(hue: 216/360, saturation: 68/100, brightness: 68/100, alpha: 1.0)
            
            DispatchQueue.main.async {
                self.currentScene?.drawingNode.addChildNode(node)
            }
        }
    }
    
    ///returns all 8 bounding box corners in world coordinates of a given target as a dictionary. Identify corners in the dictionary via keys in format of "lbd" = left bottom down / "rfu" = right front up
    /**
       returns the corners as a dictionary. Keys are in the format, e.g. "lbd" or "rfu"
       l = left , r = right , b = back , f = front , d = down , u = up
     */
    func calcNodesBoundingBox(_ target: SCNNode) -> [String: SCNVector3] {
        
        //mincorner of bounding box
        let lbd = target.convertPosition(target.boundingBox.min, to: self.currentScene?.drawingNode)
        
        //maxcorner of bounding box
        let rfu = target.convertPosition(target.boundingBox.max, to: self.currentScene?.drawingNode)
        
        
        //Determine height and width of bounding box
        let height = rfu.y - lbd.y
        originalMeshHeight = height
        
        let width = rfu.x - lbd.x
        
        
        let rbd = lbd + SCNVector3(x: width, y: 0, z: 0)
        let lbu = lbd + SCNVector3(x: 0, y: height, z: 0)
        let rbu = lbu + SCNVector3(x: width, y: 0, z: 0)
        
        let rfd = rfu - SCNVector3(x: 0, y: height, z: 0)
        let lfu = rfu - SCNVector3(x: width, y: 0, z: 0)
        let lfd = lfu - SCNVector3(x: 0, y: height, z: 0)
        
        let nodes: [String: SCNVector3] = ["lbd": lbd, "rbd": rbd, "lbu": lbu, "rbu": rbu, "lfd": lfd, "rfd": rfd, "lfu": lfu, "rfu": rfu]

        return nodes
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
    func hitTest(pointerPosition: SCNVector3) -> ARPNode? {
            guard let sceneView = self.currentView  else { return nil }
            let projectedPencilPosition = sceneView.projectPoint(pointerPosition)
            let projectedCGPoint = CGPoint(x: CGFloat(projectedPencilPosition.x), y: CGFloat(projectedPencilPosition.y))
            
            // Cast a ray from that position and find the first ARPenNode
            let hitResults = sceneView.hitTest(projectedCGPoint, options: [SCNHitTestOption.searchMode : SCNHitTestSearchMode.all.rawValue])
           
            return hitResults.filter( { $0.node != currentScene?.pencilPoint } ).first?.node.parent as? ARPNode
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
    
    ///projects the pencilPoint on a given diagonal
    /**
        searches for the nodes of the bounding box and updates their position
        pencilPoint: pencilPoint position in screen coordinates, upperCorner: the upper corner between your selectedCorner and diagonalCorner, diagonal: the diagonal between the two corners
     */
    func projectOntoDiagonal(pencilPoint: CGPoint, upperCorner: CGPoint, diagonal: CGPoint) -> CGPoint {
        let vecA = CGPoint(x: pencilPoint.x - upperCorner.x, y: pencilPoint.y - upperCorner.y)
        let scalar = dotProduct(vecA: vecA, vecB: diagonal) / dotProduct(vecA: diagonal, vecB: diagonal)
        let scalarDiagonal = CGPoint(x: diagonal.x * scalar, y: diagonal.y * scalar)
        let projectedPoint = CGPoint(x: upperCorner.x + scalarDiagonal.x, y: upperCorner.y + scalarDiagonal.y)
        return projectedPoint
    }
    
    ///calculates the dotProduct of two given vectors
    /**
        
     */
    func dotProduct(vecA: CGPoint, vecB: CGPoint)-> CGFloat{
        return (vecA.x * vecB.x + vecA.y * vecB.y)
    }
    
    ///calculates the diagonal between the two diagonalCorners of the bounding box in screen Coordinates
    /**
        
     */
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
     
    
    ///
    /**
        
     */
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
    
    ///
    /**
        
     */
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
    func unselectTarget(_ target: ARPNode) {
        target.selected = false
        selectedTargets.removeAll(where: { $0 === target })
        removeBoundingBox()
        target.name = "generic"
        target.rotation = rotationSave!
    }
    
    ///
    /**
        
     */
    func selectTarget(_ target: ARPNode) {
        if selectedTargets.count != 1 {
            target.selected = true
            target.name = "selected"
            selectedTargets.append(target)
            justSelectedSomething = true
            didSelectSomething?(target)
            
            
            rotationSave = target.rotation
            target.rotation = SCNVector4(0,0,0,0)
            target.applyTransform()
            viewBoundingBox(target)
        }
    }
}
