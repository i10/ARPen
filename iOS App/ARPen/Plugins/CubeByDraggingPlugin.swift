//
//  CubeByDraggingPlugin.swift
//  ARPen
//
//  Created by Philipp Wacker on 09.03.18.
//  Copyright © 2018 RWTH Aachen. All rights reserved.
//

import Foundation
import ARKit


class CubeByDraggingPlugin: Plugin {

    /**
     The starting point is the point of the pencil where the button was first pressed.
     If this var is nil, there was no initial point
     */
    private var startingPoint: SCNVector3?
    
    ///final box dimensions
    private var finalBoxWidth: Double?
    private var finalBoxHeight: Double?
    private var finalBoxLength: Double?
    ///final box position
    private var finalBoxCenterPos: SCNVector3?
    
    override init() {
       
        super.init()
    
        self.pluginImage = UIImage.init(named: "CubeByDraggingPlugin")
        self.pluginInstructionsImage = UIImage.init(named: "CubePluginInstructions")
        self.pluginIdentifier = "Cube"
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
            
            if let startingPoint = self.startingPoint
            {
                //see if there is an active box node that is currently being drawn. Otherwise create it
                guard let boxNode = scene.drawingNode.childNode(withName: "currentDragBoxNode", recursively: false)
                else
                {
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
                guard let boxNodeGeometry = boxNode.geometry as? SCNBox
                else
                {
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
                
                //set the position of boxNode to the center of the box
                boxNode.worldPosition = SCNVector3.init(boxCenterXPosition, boxCenterYPosition, boxCenterZPosition)
                
                //save dimensions in variables for ARPBox instantiation
                self.finalBoxWidth = Double(boxWidth)
                self.finalBoxHeight = Double(boxHeight)
                self.finalBoxLength = Double(boxLength)
            }
            
            else {
                //if the button is pressed but no startingPoint exists -> first frame with the button pressed. Set current pencil position as the start point
                self.startingPoint = scene.pencilPoint.position
            }
        }
        
        //Button not pressed anymore
        else
        {
            //if the button is not pressed, check if a startingPoint is set -> released button. Reset the startingPoint to nil and set the name of the drawn box to "finished"
            if self.startingPoint != nil {
                self.startingPoint = nil
                if let boxNode = scene.drawingNode.childNode(withName: "currentDragBoxNode", recursively: false)
                {
                    if (finalBoxLength != nil && finalBoxWidth != nil && finalBoxHeight != nil)
                    {
                        //assign a random name to the boxNode for identification in further process
                        boxNode.name = randomString(length: 32)
                        //remove "SceneKit Box"
                        boxNode.removeFromParentNode()
                        
                        //save position for new ARPBox
                        self.finalBoxCenterPos = boxNode.worldPosition
                        
                        let box = ARPBox(width: self.finalBoxWidth!, height: self.finalBoxHeight!, length: self.finalBoxLength!)
                    
                        DispatchQueue.main.async {
                            self.currentScene?.drawingNode.addChildNode(box)
                        }
                        
                        box.localTranslate(by: self.finalBoxCenterPos!)
                        box.applyTransform()
                        
                        let buildingAction = PrimitiveBuildingAction(occtRef: box.occtReference!, scene: self.currentScene!, box: box)
                        self.undoRedoManager?.actionDone(buildingAction)
                    }
                    
                }
            }
        }
    }
}
