//
//  RotationWithDevicetest.swift
//  ARPen
//
//  Created by Donna Klamma on 17.05.19.
//  Copyright © 2019 RWTH Aachen. All rights reserved.
//

import Foundation
import CoreMotion
import ARKit

class RotationWithDevicePlugin: Plugin {
    @IBOutlet weak var button1Label: UILabel!
    @IBOutlet weak var button2Label: UILabel!
    @IBOutlet weak var button3Label: UILabel!
    
    var undoButtonPressed = false
    
    var tapGesture : UITapGestureRecognizer?
    
    var startDeviceOrientation = simd_quatf()
    var updatedDeviceOrientation = simd_quatf()
    var quaternionFromStartToUpdatedDeviceOrientation = simd_quatf()
    var updatesSincePressed = 0
    
    var tapped : Bool = false
    var pressedBool: Bool = false
    var selected : Bool = false
    var firstSelection : Bool = false
    
    var rotationAxis = simd_float3()
    
    //Variables For USER STUDY TASK
    var randomAngle : Float = 0.0
    var randomAxis = simd_float3()
    var randomOrientation = simd_quatf()
    
    var ModelToRotatedBoxOrientation = simd_quatf()
    var originialBoxOrientation = simd_quatf()
    //variables for measuring
    var selectionCounter = 0
    var angleBetweenBoxAndModel : Float = 0.0
    var angleBetweenBoxAndModelEnd : Float = 0.0
    var degreesBoxWasRotated : Float = 0.0
    var degreesDeviceWasRotated: Float = 0.0
    
    var startTime : Date = Date()
    var endTime : Date = Date()
    var elapsedTime: Double = 0.0
    
    var userStudyReps = 0
    
    var studyData : [String:String] = [:]
    
    override init() {
        super.init()
        
        self.pluginIdentifier = "Direct Device"
        self.needsBluetoothARPen = false
        self.pluginGroupName = "Rotation"
        
        nibNameOfCustomUIView = "AllButtonsAndUndo"
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
        
        let pressed = buttons[Button.Button1]!
        if pressed{
            //"activate" box while buttons is pressed and select it therefore
            //project point onto image plane and see if geometry is behind it via hittest
            let projectedPenTip = CGPoint(x: Double(sceneView.projectPoint(scene.pencilPoint.position).x), y: Double(sceneView.projectPoint(scene.pencilPoint.position).y))
            var hitResults = sceneView.hitTest(projectedPenTip, options: [SCNHitTestOption.searchMode : SCNHitTestSearchMode.all.rawValue] )
            if hitResults.first?.node == model{
                hitResults.removeFirst()
            }
            if hitResults.first?.node == scene.pencilPoint{
                hitResults.removeFirst()
            }
            if let boxHit = hitResults.first?.node{
                if selected == false{
                    selected = true
                    //boxHit.geometry?.firstMaterial?.diffuse.contents = UIColor.green
                    //this is a workaround to only highlight the body as we know the object that is hit
                    box.childNode(withName: "Body", recursively: true)?.geometry?.firstMaterial?.diffuse.contents = UIColor.green
                    
                    selectionCounter = selectionCounter + 1
                    if selectionCounter == 1{
                        startTime = Date()
                        degreesDeviceWasRotated = 0.0
                    }
                    firstSelection = true
                }
            }
            
            //if just selected, initialize DeviceOrientation
            if updatesSincePressed == 0 {
                if let orientation = sceneView.pointOfView?.simdOrientation {
                    startDeviceOrientation = orientation
                }
            }
            updatesSincePressed += 1
            
            if let updatedDeviceOrient = sceneView.pointOfView?.simdOrientation {
                updatedDeviceOrientation = updatedDeviceOrient
            }
            //calculate quaternion to get from start to updated device orientation and apply the same rotation to the object
            quaternionFromStartToUpdatedDeviceOrientation = updatedDeviceOrientation * simd_inverse(startDeviceOrientation)
            
            rotationAxis = quaternionFromStartToUpdatedDeviceOrientation.axis
            rotationAxis = box.simdConvertVector(rotationAxis, from: nil)
            
            quaternionFromStartToUpdatedDeviceOrientation = simd_quatf(angle: quaternionFromStartToUpdatedDeviceOrientation.angle, axis: rotationAxis)
            quaternionFromStartToUpdatedDeviceOrientation = quaternionFromStartToUpdatedDeviceOrientation.normalized
            
            if selected == true{
                box.simdLocalRotate(by: quaternionFromStartToUpdatedDeviceOrientation)
                degreesBoxWasRotated = degreesBoxWasRotated + abs(quaternionFromStartToUpdatedDeviceOrientation.angle.radiansToDegrees)
            }
            degreesDeviceWasRotated = degreesDeviceWasRotated + abs(quaternionFromStartToUpdatedDeviceOrientation.angle.radiansToDegrees)
            startDeviceOrientation = updatedDeviceOrientation
        }
        else{
            selected = false
            box.childNode(withName: "Body", recursively: true)?.geometry?.firstMaterial?.diffuse.contents = UIColor.red
            updatesSincePressed = 0
            
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
        
        //user study task
        if checked == true && firstSelection == true && selected == false {
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
            
            pressedBool = false
            tapped = false
            firstSelection = false
            
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
        if userStudyReps == 10{
            box.removeFromParentNode()
            model.removeFromParentNode()
        }
        
        //in the case a mistake was made undo to re-do attempt
        if self.undoButtonPressed{
            box.childNode(withName: "Body", recursively: true)?.geometry?.firstMaterial?.diffuse.contents = UIColor.red
            
            elapsedTime = 0.0
            selectionCounter = 0
            degreesDeviceWasRotated = 0.0
            degreesBoxWasRotated = 0.0
            firstSelection = false
            selected = false
            
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
    
    //function for selecting objects via touchscreen interaction
    @objc func didTap(_ sender: UITapGestureRecognizer){
        guard let sceneView = self.currentView else { return }
        
        let touchPoint = sender.location(in: sceneView)
        
        let hitResults = sceneView.hitTest(touchPoint, options: [SCNHitTestOption.searchMode : SCNHitTestSearchMode.all.rawValue] )
        if let boxHit = hitResults.first?.node{
            if tapped == false{
                tapped = true
                pressedBool = true
                boxHit.geometry?.firstMaterial?.diffuse.contents = UIColor.green
                startTime = Date()
            }
            else if tapped == true{
                tapped = false
                pressedBool = false
                boxHit.geometry?.firstMaterial?.diffuse.contents = UIColor.red
            }
        }
    }
    
    override func activatePlugin(withScene scene: PenScene, andView view: ARSCNView) {
        super.activatePlugin(withScene: scene, andView: view)
        
        self.button1Label.text = "Rotate"
        self.button2Label.text = "Finish"
        self.button3Label.text = ""
        
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
            boxNode.opacity = 0.9
            
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
        if let box = currentScene?.drawingNode.childNode(withName: "currentBoxNode", recursively: false){
            box.removeFromParentNode()
        }
        
        if let modelBox = currentScene?.drawingNode.childNode(withName: "modelBoxNode", recursively: false){
            modelBox.removeFromParentNode()
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
