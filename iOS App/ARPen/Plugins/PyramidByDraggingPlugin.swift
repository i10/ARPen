//
//  PyramidByDraggingPlugin.swift
//  ARPen
//
//  Created by Krishna Subramanian on 08.06.19.
//  Copyright © 2019 RWTH Aachen. All rights reserved.
//

import Foundation
import ARKit

class PyramidByDraggingPlugin: Plugin, UserStudyRecordPluginProtocol {
    //reference to userStudyRecordManager to add new records
    var recordManager: UserStudyRecordManager!
    
    var pluginImage : UIImage? = UIImage.init(named: "PyramidPlugin")
    var pluginInstructionsImage: UIImage? = UIImage.init(named: "DefaultInstructions")
    var pluginIdentifier: String = "Create Pyramid"
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
        
        //if the button is pressed -> either set the starting point of the pyramid (first action) or scale the pyramid to fit from the starting point to the current point
        if pressed {
            if let startingPoint = self.startingPoint {
                // Use existing pyramid node; if one doesn't exist, create it.
                guard let pyramidNode = scene.drawingNode.childNode(withName: "currentDragPyramidNode", recursively: false) else {
                    let pyramidNode = SCNNode()
                    pyramidNode.name = "currentDragPyramidNode"
                    scene.drawingNode.addChildNode(pyramidNode)
                    return
                }
                
                // Calculate the width, height, and length of the pyramid from ARPen translation.
                
                let pyramidWidth = CGFloat(abs(scene.pencilPoint.position.x - startingPoint.x))
                let pyramidHeight = CGFloat(abs(scene.pencilPoint.position.y - startingPoint.y))
                let pyramidLength = CGFloat(abs(scene.pencilPoint.position.z - startingPoint.z))
                
                // Get the pyramid node geometry (if it is not a SCNPyramid, create that with the calculated dimensions)
                guard let pyramidNodeGeometry = pyramidNode.geometry as? SCNPyramid else {
                    pyramidNode.geometry = SCNPyramid.init(width: pyramidWidth, height: pyramidHeight, length: pyramidLength)
                    return
                }
                
                // Set the width, height, and lenngth of the pyramid
                pyramidNodeGeometry.width = pyramidWidth
                pyramidNodeGeometry.height = pyramidHeight
                pyramidNodeGeometry.length = pyramidLength
                
                // Calculate the center position of the pyramid node
                let pyramidCenterXPosition = scene.pencilPoint.position.x
                let pyramidCenterYPosition = startingPoint.y
                let pyramidCenterZPosition = startingPoint.z + (scene.pencilPoint.position.z - startingPoint.z)/2
                pyramidNode.position = SCNVector3.init(pyramidCenterXPosition, pyramidCenterYPosition, pyramidCenterZPosition)
            } else {
                //if the button is pressed but no startingPoint exists -> first frame with the button pressed. Set current pencil position as the start point
                self.startingPoint = scene.pencilPoint.position
            }
        } else {
            //if the button is not pressed, check if a startingPoint is set -> released button. Reset the startingPoint to nil and set the name of the drawn pyramid to "finished"
            if self.startingPoint != nil {
                self.startingPoint = nil
                if let pyramidNode = scene.drawingNode.childNode(withName: "currentDragPyramidNode", recursively: false), let pyramidNodeGeometry = pyramidNode.geometry as? SCNPyramid {
                    pyramidNode.name = "FinishedPyramidNode"
                    
                    // Store a new record with the width, height, and length of the finished pyramid.
                    let pyramidDimensionsDict = ["Width": String(describing: pyramidNodeGeometry.width), "Height": String(describing: pyramidNodeGeometry.height), "Length": String(describing: pyramidNodeGeometry.length)]
                    self.recordManager.addNewRecord(withIdentifier: "PyramidFinished", andData: pyramidDimensionsDict)
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

