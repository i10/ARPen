//
//  CylinderByDraggingPlugin.swift
//  ARPen
//
//  Created by Krishna Subramanian on 08.06.19.
//  Copyright © 2019 RWTH Aachen. All rights reserved.
//

import Foundation
import ARKit

class CylinderByDraggingPlugin: Plugin {
    //reference to userStudyRecordManager to add new records
    var recordManager: UserStudyRecordManager!
    
    /**
     The starting point is the point of the pencil where the button was first pressed.
     If this var is nil, there was no initial point
     */
    private var startingPoint: SCNVector3?
    
    
    private var finalCylinderRadius: Double?
    private var finalCylinderHeight: Double?
    private var finalCylinderPosition: SCNVector3?
    
    override init() {
        super.init()
        
        self.pluginImage = UIImage.init(named: "CylinderPlugin")
        self.pluginInstructionsImage = UIImage.init(named: "CylinderPluginInstructions")
        self.pluginIdentifier = "Cylinder"
        self.needsBluetoothARPen = false
        self.pluginGroupName = "Primitives"
        self.pluginDisabledImage = UIImage.init(named: "ARMenusPluginDisabled")
    }
    
    override func didUpdateFrame(scene: PenScene, buttons: [Button : Bool]) {
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
                
                //update cylinder Height and Radius for ARPCylinder
                finalCylinderRadius = Double(cylinderRadius)
                finalCylinderHeight = Double(cylinderHeight)

                // Calculate the center position of the cylinder node to be at the geometric center of the cylinder.
                let cylinderCenterXPosition = startingPoint.x
                let cylinderCenterYPosition = startingPoint.y + (scene.pencilPoint.position.y - startingPoint.y)/2
                let cylinderCenterZPosition = startingPoint.z + (scene.pencilPoint.position.z - startingPoint.z)/2
                cylinderNode.position = SCNVector3.init(cylinderCenterXPosition, cylinderCenterYPosition, cylinderCenterZPosition)
                
                //update cylinder position for ARPCylinder
                finalCylinderPosition = cylinderNode.position
            } else {
                //if the button is pressed but no startingPoint exists -> first frame with the button pressed. Set current pencil position as the start point
                self.startingPoint = scene.pencilPoint.position
            }
        } else {
            //if the button is not pressed, check if a startingPoint is set -> released button. Reset the startingPoint to nil and set the name of the drawn box to "finished"
            if self.startingPoint != nil {
                self.startingPoint = nil
                if let cylinderNode = scene.drawingNode.childNode(withName: "currentDragCylinderNode", recursively: false)
                {
                    //assign a random name to the boxNode for identification in further process
                    cylinderNode.name = randomString(length: 32)
                    //remove "SceneKit Box"
                    cylinderNode.removeFromParentNode()
                    
                    let cylinder = ARPCylinder(radius: finalCylinderRadius!, height: finalCylinderHeight!)
                    
                    DispatchQueue.main.async {
                        scene.drawingNode.addChildNode(cylinder)
                    }
                    
                    cylinder.localTranslate(by: self.finalCylinderPosition!)
                    cylinder.applyTransform()
                    
                    let buildingAction = PrimitiveBuildingAction(occtRef: cylinder.occtReference!, scene: self.currentScene!, cylinder: cylinder)
                    self.undoRedoManager?.actionDone(buildingAction)
                }
            }
        }
    }
}

