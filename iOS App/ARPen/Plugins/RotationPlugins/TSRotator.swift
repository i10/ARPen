//
//  TSRotator.swift
//  ARPen
//
//  Created by Andreas RF Dymek on 25.12.20.
//  Copyright © 2020 RWTH Aachen. All rights reserved.
//

import Foundation
import ARKit

/**
 This class handles the selecting and rotating objects via touch gestures
 
*/
class TSRotator {
    
    var rotationGesture : UIRotationGestureRecognizer?
    var panGesture : UIPanGestureRecognizer?
    var tapGesture : UITapGestureRecognizer?
    
    //everything needed for undo/redo
    private var initialEulerAngles: SCNVector3?
    private var diffInEulerAngles: SCNVector3?
    private var initialPos: SCNVector3?
    private var updatedPos: SCNVector3?
    
    var tapped : Bool = false
    var pressedBool: Bool = false
    var firstSelection : Bool = false
    
    var currentPoint = CGPoint()
    var previousPoint = CGPoint()
    var startRotation : Float = 0.0
    var camera = SCNNode()
    var xVector = simd_float3()
    var yVector = simd_float3()
    var zVector = simd_float3()
    
    var currentScene: PenScene?
    var currentView: ARSCNView?
    var urManager: UndoRedoManager?

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
    
    private var buttonEvents: ButtonEvents
    private var justSelectedSomething = false
    
    var didSelectSomething: ((ARPGeomNode) -> Void)?
    
    
    init() {
        buttonEvents = ButtonEvents()
    }

    ///
    /**
        
     */
    func isPivotLocatedInCenter(target: ARPGeomNode) -> Bool {
        
        let center = target.convertPosition(target.geometryNode.boundingSphere.center, to: self.currentScene?.drawingNode)

        let worldTransf = SCNVector3(target.worldTransform.m41, target.worldTransform.m42, target.worldTransform.m43)
        
        return SCNVector3EqualToVector3(center, worldTransf)
    }
    
    func activate(withScene scene: PenScene, andView view: ARSCNView, urManager: UndoRedoManager) {
    
        self.tapped = false
        self.pressedBool = false
        
        self.currentView = view
        self.currentScene = scene
        self.urManager = urManager
        
        self.tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTap(_:)))
        self.currentView?.addGestureRecognizer(tapGesture!)
        self.currentView?.isUserInteractionEnabled = true
        
        self.panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        self.currentView?.addGestureRecognizer(panGesture!)
        self.currentView?.isUserInteractionEnabled = true
        
        self.justSelectedSomething = false
    }

    
    func deactivate() {
        for target in selectedTargets {
            unselectTarget(target)
        }
        
        if let rotationGestureRecognizer = self.rotationGesture{
            self.currentView?.removeGestureRecognizer(rotationGestureRecognizer)
        }
        
        if let panGestureRecognizer = self.panGesture{
            self.currentView?.removeGestureRecognizer(panGestureRecognizer)
        }
        
        if let tapGestureRecognizer = self.tapGesture{
            self.currentView?.removeGestureRecognizer(tapGestureRecognizer)
        }
        
    }
    
    
    //function for rotating an object around x or y axis (of the camera view) by swiping across the touchscreen with one finger
    @objc func handlePan(_ sender: UIPanGestureRecognizer){
        guard let sceneView = self.currentView else { return }
        
        if pressedBool == false{
            return
        }
        
        var translation = CGPoint()
        var rotationY : Float = 0.0
        var rotationX : Float = 0.0
        var rotationQuat = simd_quatf()
        
        if sender.state == .began{
            self.currentPoint = sender.location(in: sceneView)
            translation = CGPoint(x:0, y:0)
            
            //get the camera node from the point of view
            if let cameraT = sceneView.pointOfView{
                self.camera.orientation = cameraT.orientation
            }
            
            initialEulerAngles = selectedTargets.first!.eulerAngles
            initialPos = selectedTargets.first!.position
        }
        else if sender.state == .changed{
            self.previousPoint = self.currentPoint
            self.currentPoint = sender.location(in: sceneView)
            translation = CGPoint(x: self.currentPoint.x - self.previousPoint.x,y: self.currentPoint.y - self.previousPoint.y)
            
            
            //get the positive xVector of the camera (parent) and transform it to space of box node
            self.xVector = simd_float3(x: self.camera.transform.m11, y: self.camera.transform.m12, z: self.camera.transform.m13)
            self.xVector = selectedTargets.first!.simdConvertVector(self.xVector, from: sceneView.pointOfView!.parent!)
            
            //get the positive yVector of the camera (parent) and transform it to space of box node
            self.yVector = simd_float3(x: self.camera.transform.m21, y: self.camera.transform.m22, z: self.camera.transform.m23)
            self.yVector = selectedTargets.first!.simdConvertVector(self.yVector, from: sceneView.pointOfView!.parent!)
        }
        
        else if sender.state == .ended{
            self.currentPoint = CGPoint(x:0, y:0)
            
            diffInEulerAngles = selectedTargets.first!.eulerAngles - initialEulerAngles!
            updatedPos = selectedTargets.first?.position
            
            let rotationAction = RotatingAction(occtRef: selectedTargets.first!.occtReference!, scene: self.currentScene!, diffInEulerAngles: diffInEulerAngles!, prevPos: initialPos!, newPos: updatedPos!)
            self.urManager?.actionDone(rotationAction)
        }
        
        //transform the translation of the pan across the touchscreen into radians for the rotation
        rotationX = Float(translation.x) * .pi/180.0
        rotationY = Float(translation.y) * .pi/180.0
        
        //distinguish between rotation around yAxis (with rotationX in x direction) and rotation around xAxis (with rotationY in y direction)
        if(abs(rotationX) > abs(rotationY)){
            rotationQuat = simd_quatf(angle: rotationX, axis: self.yVector)
            rotationQuat = rotationQuat.normalized
            
            if(!isPivotLocatedInCenter(target: selectedTargets.first!)){
                
                let center = selectedTargets.first!.convertPosition(selectedTargets.first!.geometryNode.boundingSphere.center, to: self.currentScene?.drawingNode)
                
                let simdCenter = simd_float3(center)
                
                selectedTargets.first!.simdRotate(by: rotationQuat, aroundTarget: simdCenter)
                selectedTargets.first!.applyTransform()
            }
            
            else{
                
                selectedTargets.first!.simdLocalRotate(by: rotationQuat)
                selectedTargets.first!.applyTransform()
            }
            
            
        }
        else{
            rotationQuat = simd_quatf(angle: rotationY, axis: self.xVector)
            rotationQuat = rotationQuat.normalized
            
            if(!isPivotLocatedInCenter(target: selectedTargets.first!)){
                
                let center = selectedTargets.first!.convertPosition(selectedTargets.first!.geometryNode.boundingSphere.center, to: self.currentScene?.drawingNode)
                
                let simdCenter = simd_float3(center)
                
                selectedTargets.first!.simdRotate(by: rotationQuat, aroundTarget: simdCenter)
                selectedTargets.first!.applyTransform()
            }
            
            else{
                
                selectedTargets.first!.simdLocalRotate(by: rotationQuat)
                selectedTargets.first!.applyTransform()
            }
        }
    }
    
    
    
    //function for selecting objects via touchscreen
    @objc func didTap(_ sender: UITapGestureRecognizer){
      
        let touchPoint = sender.location(in: self.currentView)
        
        let hitResults = self.currentView!.hitTest(touchPoint, options: [SCNHitTestOption.searchMode : SCNHitTestSearchMode.all.rawValue] )
        
        if let hit = hitResults.first?.node.parent as? ARPGeomNode {
            
            if tapped == false{
                tapped = true
                pressedBool = true
                
                hoverTarget = hit
                selectTarget(hit)
            }
            
            
            else if tapped == true && selectedTargets.first == hit{
                tapped = false
                pressedBool = false
                
                hoverTarget = nil
                unselectTarget(hit)
               
            }
        }
    }
    
    
    ///
    /**
        
     */
    func unselectTarget(_ target: ARPGeomNode) {
        target.selected = false
        target.applyTransform()
        hoverTarget = nil
        selectedTargets.removeAll(where: { $0 === target })
    }
    
    
    ///
    /**
        
     */
    func selectTarget(_ target: ARPGeomNode) {
        if selectedTargets.count != 1 {
            target.selected = true
            selectedTargets.append(target)
            justSelectedSomething = true
            didSelectSomething?(target)
            
        }
    }

}
