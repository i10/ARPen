//
//  RotationWithTSTest.swift
//  ARPen
//
//  Created by Donna Klamma on 27.05.19.
//  Copyright © 2019 RWTH Aachen. All rights reserved.
//

import Foundation
import ARKit

class RotationWithTSPlugin : Plugin {
    
    @IBOutlet weak var button1Label: UILabel!
    @IBOutlet weak var button2Label: UILabel!
    @IBOutlet weak var button3Label: UILabel!
    
    var undoButtonPressed = false
    
    var finishedView : UILabel?
    var rotationGesture : UIRotationGestureRecognizer?
    var panGesture : UIPanGestureRecognizer?
    var tapGesture : UITapGestureRecognizer?
    
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
    
    //Variables For USER STUDY TASK
    var randomAngle : Float = 0.0
    var randomAxis = simd_float3()
    var randomOrientation = simd_quatf()
    
    var userStudyReps = 0
    var ModelToRotatedBoxOrientation = simd_quatf()
    var originialBoxOrientation = simd_quatf()
    
    //variables for measuring
    var selectionCounter = 0
    var angleBetweenBoxAndModel : Float = 0.0
    var angleBetweenBoxAndModelEnd : Float = 0.0
    var degreesBoxWasRotated : Float = 0.0
    var translationSum : Float = 0.0
    var rotationOnScreen: Float = 0.0
    var startTime : Date = Date()
    var endTime : Date = Date()
    var elapsedTime: Double = 0.0
    
    var studyData : [String:String] = [:]
    
    override init() {
        super.init()
        
        self.pluginImage = UIImage.init(named: "RotationTouchscreen")
        self.pluginInstructionsImage = UIImage.init(named: "RotationTouchscreenInstructions")
        
        self.pluginIdentifier = "Touchscreen"
        self.needsBluetoothARPen = false
        self.pluginGroupName = "Rotation"
        
        nibNameOfCustomUIView = "ThreeButtons"
    }
    
    override func didUpdateFrame(scene: PenScene, buttons: [Button : Bool]){
        guard let scene = self.currentScene else {return}
        guard let box = scene.drawingNode.childNode(withName: "currentBoxNode", recursively: false) else{
            print("not found")
            return
        }
        guard let model = scene.drawingNode.childNode(withName: "modelBoxNode", recursively: false) else{
            print("not found")
            return
        }
        guard let sceneView = self.currentView else { return }
        let checked = buttons[Button.Button2]!
        
        //user study task
        if checked == true && firstSelection == true && pressedBool == false {
            elapsedTime = endTime.timeIntervalSince(startTime)
            
            //create random orientation for model
            randomAngle = Float.random(in: 0...360).degreesToRadians
            randomAxis = simd_float3(x: Float.random(in: -1...1), y: Float.random(in: -1...1), z: Float.random(in: -1...1))
            randomOrientation = simd_quatf(angle: randomAngle, axis: randomAxis)
            randomOrientation = randomOrientation.normalized
            
            //new random orientation for model
            model.simdLocalRotate(by: randomOrientation)
            //reset box Orientation
            box.simdOrientation = originialBoxOrientation
            
            firstSelection = false
            pressedBool = false
            tapped = false
            box.childNode(withName: "Body", recursively: true)?.geometry?.firstMaterial?.diffuse.contents = UIColor.red
            
            //measurement variables
            selectionCounter = 0
            degreesBoxWasRotated = 0.0
            
            ModelToRotatedBoxOrientation = box.simdOrientation * simd_inverse(model.simdOrientation)
            if(ModelToRotatedBoxOrientation.angle.radiansToDegrees <= 180.0){
                angleBetweenBoxAndModel = ModelToRotatedBoxOrientation.angle.radiansToDegrees
            }
            else{
                angleBetweenBoxAndModel = 360.0 - ModelToRotatedBoxOrientation.angle.radiansToDegrees
            }
            
            
            userStudyReps += 1
        }
        
        //make objects disappear after six reps
        if userStudyReps == 6{
            box.removeFromParentNode()
            model.removeFromParentNode()
        }
        
        //in the case a mistake was made undo to re-do attempt
        if self.undoButtonPressed == true {
            box.childNode(withName: "Body", recursively: true)?.geometry?.firstMaterial?.diffuse.contents = UIColor.red
            
            elapsedTime = 0.0
            selectionCounter = 0
            translationSum = 0.0
            degreesBoxWasRotated = 0.0
            firstSelection = false
            pressedBool = false
            tapped = false
            
            //create random orientation for model
            randomAngle = Float.random(in: 0...360).degreesToRadians
            randomAxis = simd_float3(x: Float.random(in: -1...1), y: Float.random(in: -1...1), z: Float.random(in: -1...1))
            randomOrientation = simd_quatf(angle: randomAngle, axis: randomAxis)
            randomOrientation = randomOrientation.normalized
            
            //new random orientation for model
            model.simdLocalRotate(by: randomOrientation)
            //reset box Orientation
            box.simdOrientation = originialBoxOrientation
            
            ModelToRotatedBoxOrientation = box.simdOrientation * simd_inverse(model.simdOrientation)
            if(ModelToRotatedBoxOrientation.angle.radiansToDegrees <= 180.0){
                angleBetweenBoxAndModel = ModelToRotatedBoxOrientation.angle.radiansToDegrees
            }
            else{
                angleBetweenBoxAndModel = 360.0 - ModelToRotatedBoxOrientation.angle.radiansToDegrees
            }
            
            self.undoButtonPressed = false
        }
        
    }
    
    //function for rotating an object around x or y axis (of the camera view) by swiping across the touchscreen with one finger
    @objc func handlePan(_ sender: UIPanGestureRecognizer){
        guard let scene = self.currentScene else {return}
        guard let box = scene.drawingNode.childNode(withName: "currentBoxNode", recursively: false) else{
            print("not found")
            return
        }
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
        }
        else if sender.state == .changed{
            self.previousPoint = self.currentPoint
            self.currentPoint = sender.location(in: sceneView)
            translation = CGPoint(x: self.currentPoint.x - self.previousPoint.x,y: self.currentPoint.y - self.previousPoint.y)
            
            
            //get the positive xVector of the camera (parent) and transform it to space of box node
            self.xVector = simd_float3(x: self.camera.transform.m11, y: self.camera.transform.m12, z: self.camera.transform.m13)
            self.xVector = box.simdConvertVector(self.xVector, from: sceneView.pointOfView!.parent!)
            
            //get the positive yVector of the camera (parent) and transform it to space of box node
            self.yVector = simd_float3(x: self.camera.transform.m21, y: self.camera.transform.m22, z: self.camera.transform.m23)
            self.yVector = box.simdConvertVector(self.yVector, from: sceneView.pointOfView!.parent!)
        }
        else if sender.state == .ended{
            self.currentPoint = CGPoint(x:0, y:0)
        }
        
        //transform the translation of the pan across the touchscreen into radians for the rotation
        rotationX = Float(translation.x) * .pi/180.0
        rotationY = Float(translation.y) * .pi/180.0
        
        //distinguish between rotation around yAxis (with rotationX in x direction) and rotation around xAxis (with rotationY in y direction)
        if(abs(rotationX) > abs(rotationY)){
            rotationQuat = simd_quatf(angle: rotationX, axis: self.yVector)
            rotationQuat = rotationQuat.normalized
            box.simdLocalRotate(by: rotationQuat)
        }
        else{
            rotationQuat = simd_quatf(angle: rotationY, axis: self.xVector)
            rotationQuat = rotationQuat.normalized
            box.simdLocalRotate(by: rotationQuat)
        }
        degreesBoxWasRotated = degreesBoxWasRotated + abs(rotationQuat.angle.radiansToDegrees)
        translationSum = translationSum + abs(Float(translation.x)) + abs(Float(translation.y))
    }
    
    //function for selecting objects via touchscreen
    @objc func didTap(_ sender: UITapGestureRecognizer){
        guard let scene = self.currentScene else {return}
        guard let sceneView = self.currentView else { return }
        guard let model = scene.drawingNode.childNode(withName: "modelBoxNode", recursively: false) else{
            print("not found")
            return
        }
        guard let box = scene.drawingNode.childNode(withName: "currentBoxNode", recursively: false) else{
            print("not found")
            return
        }
        
        let touchPoint = sender.location(in: sceneView)
        
        var hitResults = sceneView.hitTest(touchPoint, options: [SCNHitTestOption.searchMode : SCNHitTestSearchMode.all.rawValue] )
        if hitResults.first?.node == model{
            hitResults.removeFirst()
        }
        if let boxHit = hitResults.first?.node{
            
            if tapped == false{
                tapped = true
                pressedBool = true
                boxHit.geometry?.firstMaterial?.diffuse.contents = UIColor.green
                selectionCounter = selectionCounter + 1
                if selectionCounter == 1{
                    startTime = Date()
                }
                firstSelection = true
            }
            else if tapped == true{
                tapped = false
                pressedBool = false
                boxHit.geometry?.firstMaterial?.diffuse.contents = UIColor.red
                
                //if task is ended at this point the left amount of degrees between the objects is recorded
                ModelToRotatedBoxOrientation = box.simdOrientation * simd_inverse(model.simdOrientation)
                if(ModelToRotatedBoxOrientation.angle.radiansToDegrees <= 180.0){
                    angleBetweenBoxAndModelEnd = ModelToRotatedBoxOrientation.angle.radiansToDegrees
                }
                else{
                    angleBetweenBoxAndModelEnd = 360.0 - ModelToRotatedBoxOrientation.angle.radiansToDegrees
                }
                
                //in case task is ended at this point record endTime
                endTime = Date()
            }
        }
    }
    
    override func activatePlugin(withScene scene: PenScene, andView view: ARSCNView, urManager: UndoRedoManager) {
        super.activatePlugin(withScene: scene, andView: view, urManager: urManager)
        
        self.button1Label.text = "Rotate"
        self.button2Label.text = "Finish"
        self.button3Label.text = ""
        
        self.panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        self.currentView?.addGestureRecognizer(panGesture!)
        self.currentView?.isUserInteractionEnabled = true
        
        self.tapped = false
        self.pressedBool = false
        
        self.tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTap(_:)))
        self.currentView?.addGestureRecognizer(tapGesture!)
        self.currentView?.isUserInteractionEnabled = true
        
        //source mode: https://www.dropbox.com/s/u0tifsdbzwrt0e1/ARKit.zip?dl=0
        let ship = SCNScene(named: "art.scnassets/arkit-rocket.dae")
        let rocketNode = ship?.rootNode.childNode(withName: "Rocket", recursively: true)
        rocketNode?.scale = SCNVector3Make(0.3, 0.3, 0.3)
        let rocketNodeModel = rocketNode?.clone()
        
        let boxNode = rocketNode!
        //create Object to rotate
        if boxNode != scene.drawingNode.childNode(withName: "currentBoxNode", recursively: false){
            boxNode.position = SCNVector3(0, 0, -0.5)
            boxNode.name = "currentBoxNode"
            scene.drawingNode.addChildNode(boxNode)
        }
        else{
            boxNode.position = SCNVector3(0, 0, -0.5)
        }
        originialBoxOrientation = boxNode.simdOrientation
        
        //create random orientation for model
        randomAngle = Float.random(in: 0...360).degreesToRadians
        randomAxis = simd_float3(x: Float.random(in: -1...1), y: Float.random(in: -1...1), z: Float.random(in: -1...1))
        randomOrientation = simd_quatf(angle: Float(randomAngle), axis: randomAxis)
        randomOrientation = randomOrientation.normalized
        
        //create Object as model
        let boxModel = rocketNodeModel!
        if boxModel != scene.drawingNode.childNode(withName: "modelBoxNode", recursively: false){
            boxModel.position = SCNVector3(0, 0, -0.5)
            boxModel.name = "modelBoxNode"
            boxModel.opacity = 0.5
            
            boxModel.simdLocalRotate(by: randomOrientation)
            scene.drawingNode.addChildNode(boxModel)
        }
        else{
            boxModel.position = SCNVector3(0, 0, -0.5)
        }
        
        ModelToRotatedBoxOrientation = boxNode.simdOrientation * simd_inverse(boxModel.simdOrientation)
        if(ModelToRotatedBoxOrientation.angle.radiansToDegrees <= 180.0){
            angleBetweenBoxAndModel = ModelToRotatedBoxOrientation.angle.radiansToDegrees
        }
        else{
            angleBetweenBoxAndModel = 360.0 - ModelToRotatedBoxOrientation.angle.radiansToDegrees
        }
    }
    
    override func deactivatePlugin() {
        if let boxNode = currentScene?.drawingNode.childNode(withName: "currentBoxNode", recursively: false){
            boxNode.removeFromParentNode()
        }
        
        if let boxModel = currentScene?.drawingNode.childNode(withName: "modelBoxNode", recursively: false){
            boxModel.removeFromParentNode()
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
        
        super.deactivatePlugin()
    }
    
    @IBAction func softwarePenButtonPressed(_ sender: UIButton) {
        var buttonEventDict = [String: Any]()
        switch sender.tag {
        case 2:
            buttonEventDict = ["buttonPressed": Button.Button2, "buttonState" : true]
        case 3:
            buttonEventDict = ["buttonPressed": Button.Button3, "buttonState" : true]
        default:
            print("other button pressed")
        }
        NotificationCenter.default.post(name: .softwarePenButtonEvent, object: nil, userInfo: buttonEventDict)
    }
    
    @IBAction func softwarePenButtonReleased(_ sender: UIButton) {
        var buttonEventDict = [String: Any]()
        switch sender.tag {
        case 2:
            buttonEventDict = ["buttonPressed": Button.Button2, "buttonState" : false]
        case 3:
            buttonEventDict = ["buttonPressed": Button.Button3, "buttonState" : false]
        default:
            print("other button pressed")
        }
        NotificationCenter.default.post(name: .softwarePenButtonEvent, object: nil, userInfo: buttonEventDict)
    }
    @IBAction func undoButtonPressed(_ sender: Any) {
        self.undoButtonPressed = true
    }
    
}
