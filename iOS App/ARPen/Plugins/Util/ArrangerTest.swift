//
//  ArrangerTest.swift
//  ARPen
//
//  Created by Andreas RF Dymek on 31.10.20.
//  Copyright © 2020 RWTH Aachen. All rights reserved.
//

import Foundation
import ARKit

/**
This class handles the selecting and arranging and "visiting" of objects, as this functionality is shared across multiple plugins. An examplary usage can be seen in `CombinePluginTutorial.swift`.
To "visit" means to march down the hierarchy of a node, e.g. to rearrange the object which form a Boolean operation.
*/
class ArrangerTest {
    
    var currentScene: PenScene?
    var currentView: ARSCNView?
    
    /// The time (in seconds) after which holding the main button on an object results in dragging it.
    static let timeTillDrag: Double = 1
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
    
    //Taken from Mohammed, Farhadiba - Scaling study
    //compute the diagonals to drag the corner along
    func lineBetweenNodes(positionA: SCNVector3, positionB: SCNVector3, inScene: SCNScene) -> SCNNode {
        
        let vector = SCNVector3(positionA.x - positionB.x, positionA.y - positionB.y, positionA.z - positionB.z)
        
        let distance = sqrt(vector.x * vector.x + vector.y * vector.y + vector.z * vector.z)
        
        let midPosition = SCNVector3 (x:(positionA.x + positionB.x) / 2, y:(positionA.y + positionB.y) / 2, z:(positionA.z + positionB.z) / 2)

        let lineGeometry = SCNCylinder()
        lineGeometry.radius = 0.001
        lineGeometry.height = CGFloat(distance)
        lineGeometry.radialSegmentCount = 5
        lineGeometry.firstMaterial!.diffuse.contents = UIColor.systemGray

        let lineNode = SCNNode(geometry: lineGeometry)
        lineNode.opacity = 1
        lineNode.position = midPosition
        lineNode.look (at: positionB, up: inScene.rootNode.worldUp, localFront: lineNode.worldUp)
        return lineNode
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
            && ((Date() - (lastClickTime ?? Date())) > ArrangerTest.timeTillDrag
                || (lastPenPosition?.distance(vector: scene.pencilPoint.position) ?? 0) > ArrangerTest.maxDistanceTillDrag) {
            
            dragging = true
            
            if ArrangerTest.snapWhenDragging {
                    
                    if selectedTargets.count != 0 {
                        
                        selectedTargets.last!.position = selectedTargets.last!.boundingBox.min
                        
                        let edge14_node = lineBetweenNodes(positionA: selectedTargets.last!.position, positionB: selectedTargets.last!.boundingBox.min, inScene: self.currentScene!)
                        

                        //SCNVector3 with position of bounding box - min
                        let node_min = selectedTargets.last!.boundingBox.min
                        print("This is the minimal corner of the bounding box")
                        print(node_min)
                        
                        //SCNVector3 with position of bounding box - max
                        let node_max = selectedTargets.last!.boundingBox.max
                        print("This is the maximal corner of the bounding box")
                        print(node_max)
                        
                        //Determine height, width and length of bounding box
                        let height = node_max.y - node_min.y
                        let length = node_max.z - node_min.z
                        let width = node_max.x - node_min.x
                        
                        //vector of the halfs of every dimension, to determine center
                        let dimensions = SCNVector3(x: width/2, y: height/2, z: length/2)
                        
                        //ll2
                        let sphere_min = SCNSphere(radius: 0.004)
                        sphere_min.firstMaterial?.diffuse.contents = UIColor(red: 1, green: 0, blue: 0, alpha: 1)
                        let node_sphere_min = SCNNode(geometry: sphere_min)
                        node_sphere_min.position = node_min
                        
                        DispatchQueue.main.async {
                            self.currentScene?.drawingNode.addChildNode(node_sphere_min)
                            self.currentScene?.drawingNode.addChildNode(edge14_node)
    
                         }
                                                
                        //get the center
                        let center = selectedTargets.reduce(SCNVector3(0,0,0), {$0 + ($1.position + dimensions)}) / Float(selectedTargets.count)
                        print(center)
                                          
                        let shift = scene.pencilPoint.position - center
                        
                        for target in selectedTargets
                        {
                            target.position += shift
                            //selectedTargets.last!.boundingBox.min += shift
                            //selectedTargets.last!.boundingBox.max += shift
                        }
        
  
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
        if button == .Button1,
            let scene = currentScene {
            if let hit = hitTest(pointerPosition: scene.pencilPoint.position) as? ARPGeomNode {
                if hit.parent?.parent === visitTarget || visitTarget == nil {
                    visitTarget(hit)
                } else {
                    leaveTarget()
                }
            } else {
                leaveTarget()
            }
        }
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
    
    
    func selectTarget(_ target: ARPNode) {
        target.selected = true
        selectedTargets.append(target)
        justSelectedSomething = true
        didSelectSomething?(target)
    }
    
    
    func unselectTarget(_ target: ARPNode) {
        target.selected = false
        selectedTargets.removeAll(where: { $0 === target })
    }
    
    
    //hitTest
    func hitTest(pointerPosition: SCNVector3) -> ARPNode? {
            guard let sceneView = self.currentView  else { return nil }
            let projectedPencilPosition = sceneView.projectPoint(pointerPosition)
            let projectedCGPoint = CGPoint(x: CGFloat(projectedPencilPosition.x), y: CGFloat(projectedPencilPosition.y))
            
            // Cast a ray from that position and find the first ARPenNode
            let hitResults = sceneView.hitTest(projectedCGPoint, options: [SCNHitTestOption.searchMode : SCNHitTestSearchMode.all.rawValue])
           
            return hitResults.filter( { $0.node != currentScene?.pencilPoint } ).first?.node.parent as? ARPNode
    }
    
    
    //function to make the bounding box visible
    func toggleBoundingBox(){
        
         guard let scene = self.currentScene else {return}
        
         let node = selectedTargets.last
         node!.position = node!.boundingBox.min
        
         //node?.convertPosition(node!.position, to: nil)
                                 
         let node_min = node!.boundingBox.min
         print(node_min)

         let node_max = node!.boundingBox.max
         print(node_max)
      
         
         //Spheres
         //ll2
         let sphere_min = SCNSphere(radius: 0.002)
         sphere_min.firstMaterial?.diffuse.contents = UIColor.systemGray
         let node_sphere_min = SCNNode(geometry: sphere_min)
         node_sphere_min.position = node_min
  
         //ur1
         let sphere_max = SCNSphere(radius: 0.002)
         sphere_max.firstMaterial?.diffuse.contents = UIColor.systemGray
         let node_sphere_max = SCNNode(geometry: sphere_max)
         node_sphere_max.position = node_max
         
         //Determine height, width and length of bounding box
         let height = node_max.y - node_min.y
         let length = node_max.z - node_min.z
         let width = node_max.x - node_min.x
                                 
         //Adding 6 additional spheres for other corners of Bounding Box
         //lr2
         let lr2_sphere = SCNSphere(radius: 0.002)
         lr2_sphere.firstMaterial?.diffuse.contents = UIColor.systemGray
         let lr2_node = SCNNode(geometry: lr2_sphere)
         lr2_node.position = node_min + SCNVector3(x: width, y: 0, z: 0)
         
         //ur2
         let ur2_sphere = SCNSphere(radius: 0.002)
         ur2_sphere.firstMaterial?.diffuse.contents = UIColor.systemGray
         let ur2_node = SCNNode(geometry: ur2_sphere)
         ur2_node.position = lr2_node.position + SCNVector3(x: 0, y: height, z: 0)
         
         //ul2
         let ul2_sphere = SCNSphere(radius: 0.002)
         ul2_sphere.firstMaterial?.diffuse.contents = UIColor.systemGray
         let ul2_node = SCNNode(geometry: ul2_sphere)
         ul2_node.position = node_min + SCNVector3(x: 0, y: height, z: 0)
         
         //lr1
         let lr1_sphere = SCNSphere(radius: 0.002)
         lr1_sphere.firstMaterial?.diffuse.contents = UIColor.systemGray
         let lr1_node = SCNNode(geometry: lr1_sphere)
         lr1_node.position = node_max - SCNVector3(x: 0, y: height, z: 0)
         
         //ul1
         let ul1_sphere = SCNSphere(radius: 0.002)
         ul1_sphere.firstMaterial?.diffuse.contents = UIColor.systemGray
         let ul1_node = SCNNode(geometry: ul1_sphere)
         ul1_node.position = node_max - SCNVector3(x: width, y: 0, z: 0)
         
         //ll1
         let ll1_sphere = SCNSphere(radius: 0.002)
         ll1_sphere.firstMaterial?.diffuse.contents = UIColor.systemGray
         let ll1_node = SCNNode(geometry: ll1_sphere)
         ll1_node.position = lr1_node.position - SCNVector3(x: width, y: 0, z: 0)
         

        //edges
        //edge1
        let edge1_node = lineBetweenNodes(positionA: ul1_node.position, positionB: ll1_node.position, inScene: scene)
        let edge2_node = lineBetweenNodes(positionA: ul1_node.position, positionB: node_sphere_max.position, inScene: scene)
        let edge3_node = lineBetweenNodes(positionA: node_sphere_max.position, positionB: lr1_node.position, inScene: scene)
        let edge4_node = lineBetweenNodes(positionA: node_sphere_max.position, positionB: lr1_node.position, inScene: scene)
        let edge5_node = lineBetweenNodes(positionA: ll1_node.position, positionB: lr1_node.position, inScene: scene)
        let edge6_node = lineBetweenNodes(positionA: ul1_node.position, positionB: ul2_node.position, inScene: scene)
        let edge7_node = lineBetweenNodes(positionA: ll1_node.position, positionB: node_sphere_min.position, inScene: scene)
        let edge8_node = lineBetweenNodes(positionA: node_sphere_max.position, positionB: ur2_node.position, inScene: scene)
        let edge9_node = lineBetweenNodes(positionA: lr1_node.position, positionB: lr2_node.position, inScene: scene)
        let edge10_node = lineBetweenNodes(positionA: node_sphere_min.position, positionB: lr2_node.position, inScene: scene)
        let edge11_node = lineBetweenNodes(positionA: lr2_node.position, positionB: ur2_node.position, inScene: scene)
        let edge12_node = lineBetweenNodes(positionA: node_sphere_min.position, positionB: ul2_node.position, inScene: scene)
        let edge13_node = lineBetweenNodes(positionA: ur2_node.position, positionB: ul2_node.position, inScene: scene)
        
 
        DispatchQueue.main.async {
            self.currentScene?.drawingNode.addChildNode(node_sphere_min)
            self.currentScene?.drawingNode.addChildNode(node_sphere_max)
            self.currentScene?.drawingNode.addChildNode(ll1_node)
            self.currentScene?.drawingNode.addChildNode(lr1_node)
            self.currentScene?.drawingNode.addChildNode(ul1_node)
            self.currentScene?.drawingNode.addChildNode(lr2_node)
            self.currentScene?.drawingNode.addChildNode(ur2_node)
            self.currentScene?.drawingNode.addChildNode(ul2_node)
            self.currentScene?.drawingNode.addChildNode(edge1_node)
            self.currentScene?.drawingNode.addChildNode(edge2_node)
            self.currentScene?.drawingNode.addChildNode(edge3_node)
            self.currentScene?.drawingNode.addChildNode(edge4_node)
            self.currentScene?.drawingNode.addChildNode(edge5_node)
            self.currentScene?.drawingNode.addChildNode(edge6_node)
            self.currentScene?.drawingNode.addChildNode(edge7_node)
            self.currentScene?.drawingNode.addChildNode(edge8_node)
            self.currentScene?.drawingNode.addChildNode(edge9_node)
            self.currentScene?.drawingNode.addChildNode(edge10_node)
            self.currentScene?.drawingNode.addChildNode(edge11_node)
            self.currentScene?.drawingNode.addChildNode(edge12_node)
            self.currentScene?.drawingNode.addChildNode(edge13_node)
         }

     }
    
    
}


