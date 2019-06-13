//
//  CubeByDraggingPlugin.swift
//  ARPen
//
//  Created by Philipp Wacker on 09.03.18.
//  Copyright © 2018 RWTH Aachen. All rights reserved.
//

import Foundation
import ARKit

//include the UserStudyRecordPluginProtocol to demo recording of user study data
class CubeByDraggingPlugin: Plugin, UserStudyRecordPluginProtocol {
    //reference to userStudyRecordManager to add new records
    var recordManager: UserStudyRecordManager!
    
    var pluginImage : UIImage? = UIImage.init(named: "CubeByDraggingPlugin")
    var pluginInstructionsImage: UIImage? = UIImage.init(named: "CubePluginInstructions")
    var pluginIdentifier: String = "Create Cube"
    var needsBluetoothARPen: Bool = false
    var pluginDisabledImage: UIImage? = UIImage.init(named: "ARMenusPluginDisabled")
    var currentScene : PenScene?
    var currentView: ARSCNView?
    
    /**
     The starting point is the point of the pencil where the button was first pressed.
     If this var is nil, there was no initial point
     */
    private var startingPoint: SCNVector3?
    
    func didUpdateFrame(scene: PenScene, buttons: [Button : Bool]) {
        guard scene.markerFound else {
            //Don't reset the previous point to avoid restarting cube if the marker detection failed for some frames
            //self.startingPoint = nil
            return
        }
        
        //Check state of the first button -> used to create the cube
        let pressed = buttons[Button.Button1]!
        
        //if the button is pressed -> either set the starting point of the cube (first action) or scale the cube to fit from the starting point to the current point
        if pressed {
            if let startingPoint = self.startingPoint {
                //see if there is an active box node that is currently being drawn. Otherwise create it
                guard let boxNode = scene.drawingNode.childNode(withName: "currentDragBoxNode", recursively: false) else {
                    let boxNode = SCNNode()
                    boxNode.name = "currentDragBoxNode"
                    scene.drawingNode.addChildNode(boxNode)
                    return
                }
                
                //calculate the dimensions of the box to fit between the starting point and the current pencil position (opposite corners)
                let boxWidth = abs(scene.pencilPoint.position.x - startingPoint.x)
                let boxHeight = abs(scene.pencilPoint.position.y - startingPoint.y)
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
                
                //calculate the center position of the box node (halfway between the two corners startingPoint and current pencil position)
                let boxCenterXPosition = startingPoint.x + (scene.pencilPoint.position.x - startingPoint.x)/2
                let boxCenterYPosition = startingPoint.y + (scene.pencilPoint.position.y - startingPoint.y)/2
                let boxCenterZPosition = startingPoint.z + (scene.pencilPoint.position.z - startingPoint.z)/2
                boxNode.position = SCNVector3.init(boxCenterXPosition, boxCenterYPosition, boxCenterZPosition)
            } else {
                //if the button is pressed but no startingPoint exists -> first frame with the button pressed. Set current pencil position as the start point
                self.startingPoint = scene.pencilPoint.position
            }
        } else {
            //if the button is not pressed, check if a startingPoint is set -> released button. Reset the startingPoint to nil and set the name of the drawn box to "finished"
            if self.startingPoint != nil {
                self.startingPoint = nil
                if let boxNode = scene.drawingNode.childNode(withName: "currentDragBoxNode", recursively: false), let boxNodeGeometry = boxNode.geometry as? SCNBox {
                    boxNode.name = "FinishedBoxNode"
                    
                    //store a new record with the size of the finished box
                    let boxDimensionsDict = ["Width" : String(describing: boxNodeGeometry.width), "Height" : String(describing: boxNodeGeometry.height), "Length" : String(describing: boxNodeGeometry.length)]
                    self.recordManager.addNewRecord(withIdentifier: "BoxFinished", andData: boxDimensionsDict)
                }
            }
            
        }

        
    }
   
    func activatePlugin(withScene scene: PenScene, andView view: ARSCNView) {
        self.currentScene = scene
        self.currentView = view
    }
    
    func deactivatePlugin() {
        self.currentScene = nil
        self.currentView = nil
    }
    
}
