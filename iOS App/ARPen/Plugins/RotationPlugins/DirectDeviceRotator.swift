//
//  DirectDeviceRotator.swift
//  ARPen
//
//  Created by Andreas RF Dymek on 10.12.20.
//  Copyright © 2020 RWTH Aachen. All rights reserved.
//
import Foundation
import ARKit

/**
This class handles the selecting and rotation of meshes.
 */
class DirectDeviceRotator {
    
    var currentScene: PenScene?
    var currentView: ARSCNView?
    var urManager: UndoRedoManager?
    
    //everything needed for undo/redo
    private var initialEulerAngles: SCNVector3?
    private var diffInEulerAngles: SCNVector3?
    private var initialPos: SCNVector3?
    private var updatedPos: SCNVector3?

    
    //counts the updates since selecting a mesh
    var updatesSincePressed = 0
    //the device orientation when rotation button is first pressed
    var startDeviceOrientation = simd_quatf()
    //the updated device orientation
    var updatedDeviceOrientation = simd_quatf()
    var quaternionFromStartToUpdatedDeviceOrientation = simd_quatf()
    var rotationAxis = simd_float3()

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
    
    var visitTarget: ARPGeomNode?
    private var buttonEvents: ButtonEvents
    private var justSelectedSomething = false

    
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
        
        self.visitTarget = nil
        self.justSelectedSomething = false
    }

    func deactivate() {
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
            
        //geometry was selected
        if selectedTargets.count == 1 {
            let pressed = buttons[Button.Button2]!
            
            if pressed
            {
                //"activate" box while buttons is pressed and select it therefore
                //project point onto image plane and see if geometry is behind it via hittest
   
                //if just selected, initialize DeviceOrientation
                if updatesSincePressed == 0 {
                    if let orientation = self.currentView!.pointOfView?.simdOrientation {
                        startDeviceOrientation = orientation
                    }
                }
                
                updatesSincePressed += 1
                
                if let updatedDeviceOrient = self.currentView!.pointOfView?.simdOrientation {
                    updatedDeviceOrientation = updatedDeviceOrient
                }
                
                //calculate quaternion to get from start to updated device orientation and apply the same rotation to the object
                quaternionFromStartToUpdatedDeviceOrientation = updatedDeviceOrientation * simd_inverse(startDeviceOrientation)
                
                rotationAxis = quaternionFromStartToUpdatedDeviceOrientation.axis
                rotationAxis = selectedTargets.first!.simdConvertVector(rotationAxis, from: nil)
                
                quaternionFromStartToUpdatedDeviceOrientation = simd_quatf(angle: quaternionFromStartToUpdatedDeviceOrientation.angle, axis: rotationAxis)
                quaternionFromStartToUpdatedDeviceOrientation = quaternionFromStartToUpdatedDeviceOrientation.normalized
                
            
                if(!isPivotLocatedInCenter(target: selectedTargets.first!)){
                    let centerBefore = selectedTargets.first!.convertPosition(selectedTargets.first!.geometryNode.boundingSphere.center, to: self.currentScene?.drawingNode)
                    selectedTargets.first!.simdLocalRotate(by: quaternionFromStartToUpdatedDeviceOrientation)
                    let centerAfter = selectedTargets.first!.convertPosition(selectedTargets.first!.geometryNode.boundingSphere.center, to: self.currentScene?.drawingNode)
                    let diff = centerBefore - centerAfter
                    selectedTargets.first!.position += diff
                }
                
                else{
                    selectedTargets.first!.simdLocalRotate(by: quaternionFromStartToUpdatedDeviceOrientation)
                }
            
                startDeviceOrientation = updatedDeviceOrientation
            }
      
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
            
        case .Button2:
            if selectedTargets.count == 1 {
                initialEulerAngles = selectedTargets.first!.eulerAngles
                initialPos = selectedTargets.first!.position
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
            if let target = hoverTarget, !justSelectedSomething {
                    if selectedTargets.contains(target) {
                        unselectTarget(target)
                    }
                }
            justSelectedSomething = false
            
            
        case .Button2:
            if selectedTargets.count == 1 {
                
                DispatchQueue.global(qos: .userInitiated).async {
                    // Do this in the background, as it may cause a time-intensive rebuild in the parent object
                    self.selectedTargets.first!.applyTransform()
                }

                diffInEulerAngles = selectedTargets.first!.eulerAngles - initialEulerAngles!
                
                updatedPos = selectedTargets.first!.position
                
                let rotationAction = RotatingAction(occtRef: selectedTargets.first!.occtReference!, scene: self.currentScene!, diffInEulerAngles: diffInEulerAngles!, prevPos: initialPos!, newPos: updatedPos!)
                self.urManager?.actionDone(rotationAction)
                
                updatesSincePressed = 0
            }
            
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
    func unselectTarget(_ target: ARPGeomNode) {
        target.selected = false
        selectedTargets.removeAll(where: { $0 === target })
        hoverTarget = nil
        target.name = "generic"
    }
    
    ///
    /**
        
     */
    func selectTarget(_ target: ARPGeomNode) {
        if selectedTargets.count != 1 {
            target.selected = true
            target.name = "selected"
            selectedTargets.append(target)
            justSelectedSomething = true
            didSelectSomething?(target)
            updatesSincePressed = 0
        }
    }
    
}
