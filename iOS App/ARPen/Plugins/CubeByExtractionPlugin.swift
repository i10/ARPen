//
//  CubeByExtractionPlugin.swift
//  ARPen
//
//  Created by Philipp Wacker on 09.03.18.
//  Copyright © 2018 RWTH Aachen. All rights reserved.
//

import Foundation
import ARKit

class CubeByExtractionPlugin: Plugin,UserStudyRecordPluginProtocol {
    var recordManager: UserStudyRecordManager!
    
    /**
     The starting point is the point of the pencil where the button was first pressed.
     If this var is nil, there was no initial point
     */
    private var startingPoint: SCNVector3?
    
    override init() {
        super.init()
        
        self.pluginImage = UIImage.init(named: "CubeByExtractionPlugin")
        self.pluginInstructionsImage = UIImage.init(named: "ExtrudePluginInstructions")
        self.pluginIdentifier = "Extrude"
        self.needsBluetoothARPen = false
        self.pluginDisabledImage = UIImage.init(named: "CubeByExtractionPluginDisabled")
        
        nibNameOfCustomUIView = "CubeByExtractionPlugin"
    }
   
    override func didUpdateFrame(scene: PenScene, buttons: [Button : Bool]) {
        guard scene.markerFound else {
            //Don't reset the previous point to avoid restarting cube if the marker detection failed for some frames
            //self.startingPoint = nil
            return
        }
        //Check state of the first button -> used to create the base of the cube
        let button1Pressed = buttons[Button.Button1]!
        
        //if the button is pressed -> either set the starting point of the cube (first action) or scale the base to fit from the starting point to the x&z of the current point
        if button1Pressed {
            if let startingPoint = self.startingPoint {
                //see if there is an active box node that is currently being drawn. Otherwise create it
                guard let boxNode = scene.drawingNode.childNode(withName: "currentExtractionBoxNode", recursively: false) else {
                    let boxNode = SCNNode()
                    boxNode.name = "currentExtractionBoxNode"
                    scene.drawingNode.addChildNode(boxNode)
                    return
                }
                
                //calculate the dimensions of the box to fit between the starting point and the current x&z of the pencil position (opposite corners of the base)
                let boxWidth = abs(scene.pencilPoint.position.x - startingPoint.x)
                let boxHeight = 0.001
                let boxLength = abs(scene.pencilPoint.position.z - startingPoint.z)
                
                //get the box node geometry (if it is not a SCNBox, create that with the calculated dimensions)
                guard let boxNodeGeometry = boxNode.geometry as? SCNBox else {
                    boxNode.geometry = SCNBox.init(width: CGFloat(boxWidth), height: CGFloat(boxHeight), length: CGFloat(boxLength), chamferRadius: 0.0)
                    return
                }
                //set the dimensions of the box
                boxNodeGeometry.width = CGFloat(boxWidth)
                boxNodeGeometry.height = CGFloat(boxHeight)
                boxNodeGeometry.length = CGFloat(boxLength)
                
                //calculate the center position of the box node (halfway between the two base corners startingPoint and x&z of the current pencil position)
                let boxCenterXPosition = startingPoint.x + (scene.pencilPoint.position.x - startingPoint.x)/2
                let boxCenterYPosition = startingPoint.y
                let boxCenterZPosition = startingPoint.z + (scene.pencilPoint.position.z - startingPoint.z)/2
                boxNode.position = SCNVector3.init(boxCenterXPosition, boxCenterYPosition, boxCenterZPosition)
            } else {
                //if the button is pressed but no startingPoint exists -> first frame with the button pressed. Set current pencil position as the start point
                self.startingPoint = scene.pencilPoint.position
                //if there is a current active box node, set this to finished as now a new box will be created
                if let boxNode = scene.drawingNode.childNode(withName: "currentExtractionBoxNode", recursively: false) {
                    boxNode.name = "FinishedBoxNode"
                    
                    //store a new record with the position of the finished box
                    let boxPositionsDict = ["X" : String(describing: boxNode.position.x), "Y" : String(describing: boxNode.position.y), "Z" : String(describing: boxNode.position.z)]
                    self.recordManager.addNewRecord(withIdentifier: "ExtrusionBoxFinished", andData: boxPositionsDict)
                    
                }
            }
        } else {
            //if the button is not pressed, reset the startingPoint to be ready for a new base drawing. The name of the box node is not set to 'finished' as the extraction (with button2) can still happen
            self.startingPoint = nil
        }
        
        //Check state of the second button -> used to extract a cube from last drawn base
        //TODO: change so that it adjusts the closest cube
        let button2Pressed = buttons[Button.Button2]!
        
        //if the button is pressed -> check if a currently active box node exists, otherwise return
        if button2Pressed {
            //check if an active box node exists and its geometry is a SCNBox. Otherwise return
            guard let boxNode = scene.drawingNode.childNode(withName: "currentExtractionBoxNode", recursively: false), let boxNodeGeometry = boxNode.geometry as? SCNBox else {
                return
            }
            
            //calculate the heigth of the box and the new position (y-dimension)
            let boxHeight = abs(scene.pencilPoint.position.y - (boxNode.position.y - Float(boxNodeGeometry.height)/2))
            let boxCenterYPosition = boxNode.position.y + (boxHeight - Float(boxNodeGeometry.height))/2
            
            //update box geometry and position to show changes
            boxNodeGeometry.height = CGFloat(boxHeight)
            boxNode.position.y = boxCenterYPosition
        }
    }
    
    @IBAction func secondSoftwareButtonPressed(_ sender: Any) {
        let buttonEventDict:[String: Any] = ["buttonPressed": Button.Button2, "buttonState" : true]
        NotificationCenter.default.post(name: .softwarePenButtonEvent, object: nil, userInfo: buttonEventDict)
    }
    
    @IBAction func secondSoftwareButtonReleased(_ sender: Any) {
        let buttonEventDict:[String: Any] = ["buttonPressed": Button.Button2, "buttonState" : false]
        NotificationCenter.default.post(name: .softwarePenButtonEvent, object: nil, userInfo: buttonEventDict)
    }
}
