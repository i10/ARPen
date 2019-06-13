//
//  CylinderByDraggingPlugin.swift
//  ARPen
//
//  Created by Krishna Subramanian on 08.06.19.
//  Copyright © 2019 RWTH Aachen. All rights reserved.
//

import Foundation
import ARKit

class CylinderByDraggingPlugin: Plugin, UserStudyRecordPluginProtocol {
    //reference to userStudyRecordManager to add new records
    var recordManager: UserStudyRecordManager!
    
    var pluginImage : UIImage? = UIImage.init(named: "CylinderPlugin")
    var pluginInstructionsImage: UIImage? = UIImage.init(named: "DefaultInstructions")
    var pluginIdentifier: String = "Create Cylinder"
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
                // Use existing sphere node; if one doesn't exist, create it.
                guard let cylinderNode = scene.drawingNode.childNode(withName: "currentDragCylinderNode", recursively: false) else {
                    let cylinderNode = SCNNode()
                    cylinderNode.name = "currentDragCylinderNode"
                    scene.drawingNode.addChildNode(cylinderNode)
                    return
                }
                
                // Calculate the radius and height of the cylinder from ARPen translation.
                let cylinderRadius = CGFloat(abs(scene.pencilPoint.position.x - startingPoint.x))
                let cylinderHeight = CGFloat(abs(scene.pencilPoint.position.y - startingPoint.y))
                
                // Get the cylinder node geometry (if it is not a SCNCylinder, create that with the calculated dimensions)
                guard let cylinderNodeGeometry = cylinderNode.geometry as? SCNCylinder else {
                    cylinderNode.geometry = SCNCylinder.init(radius: cylinderRadius, height: cylinderHeight)
                    return
                }
                
                // Set the radius and height of the cylinder
                cylinderNodeGeometry.radius = cylinderRadius
                cylinderNodeGeometry.height = cylinderHeight

                // Calculate the center position of the cylinder node to be at the geometric center of the cylinder.
                let cylinderCenterXPosition = startingPoint.x
                let cylinderCenterYPosition = startingPoint.y + (scene.pencilPoint.position.y - startingPoint.y)/2
                let cylinderCenterZPosition = startingPoint.z + (scene.pencilPoint.position.z - startingPoint.z)/2
                cylinderNode.position = SCNVector3.init(cylinderCenterXPosition, cylinderCenterYPosition, cylinderCenterZPosition)
            } else {
                //if the button is pressed but no startingPoint exists -> first frame with the button pressed. Set current pencil position as the start point
                self.startingPoint = scene.pencilPoint.position
            }
        } else {
            //if the button is not pressed, check if a startingPoint is set -> released button. Reset the startingPoint to nil and set the name of the drawn box to "finished"
            if self.startingPoint != nil {
                self.startingPoint = nil
                if let cylinderNode = scene.drawingNode.childNode(withName: "currentDragCylinderNode", recursively: false), let cylinderNodeGeometry = cylinderNode.geometry as? SCNCylinder {
                    cylinderNode.name = "FinishedCylinderNode"
                    
                    // Store a new record with the radius and height of the finished cylinder.
                    let cylinderDimensionsRect = ["Radius": String(describing: cylinderNodeGeometry.radius), "Height" : String(describing: cylinderNodeGeometry.height)]
                    self.recordManager.addNewRecord(withIdentifier: "CylinderFinished", andData: cylinderDimensionsRect)
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

