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
This class handles the "visiting" and selecting of meshes. When one mesh is selected the boundingBox corners are also visualized. We hover over corerns and then select them using the PenRayScaling Plugin. Scaling then happens in the update method.
 
 Scaling is supporred for one selected mesh. Mulitple selection is not possible.
 Some code was inspired by the work of Farhadiba Mohammed on ARPen.
*/
class DirectDeviceRotator {
    
    var currentScene: PenScene?
    var currentView: ARSCNView?
    
    
    
    
    //counts the updates since selecting a mesh
    var updatesSincePressed = 0
    
    //the device orientation when rotation button is first pressed
    var startDeviceOrientation = simd_quatf()
    //the updated device orientation
    var updatedDeviceOrientation = simd_quatf()
    //
    var quaternionFromStartToUpdatedDeviceOrientation = simd_quatf()
    //
    var rotationAxis = simd_float3()
    //
    var degreesBoxWasRotated : Float = 0.0
    //
    var degreesDeviceWasRotated: Float = 0.0
    
    
    
    
    
    
    
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
       
        //check whether or not you hover over created geometry
        if let hit = hitTest(pointerPosition: scene.pencilPoint.position) {
            hoverTarget = hit
        } else {
            hoverTarget = nil
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
                
                
                selectedTargets.first!.simdLocalRotate(by: quaternionFromStartToUpdatedDeviceOrientation)
                degreesBoxWasRotated = degreesBoxWasRotated + abs(quaternionFromStartToUpdatedDeviceOrientation.angle.radiansToDegrees)
                
                degreesDeviceWasRotated = degreesDeviceWasRotated + abs(quaternionFromStartToUpdatedDeviceOrientation.angle.radiansToDegrees)
                startDeviceOrientation = updatedDeviceOrientation
            }
      
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
            
        case .Button2:
            for target in selectedTargets {
                DispatchQueue.global(qos: .userInitiated).async {
                    // Do this in the background, as it may cause a time-intensive rebuild in the parent object
                    target.applyTransform()
                }
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
    func unselectTarget(_ target: ARPNode) {
        target.selected = false
        selectedTargets.removeAll(where: { $0 === target })
      
        target.name = "generic"
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
            
            
            updatesSincePressed = 0
        }
    }
}
