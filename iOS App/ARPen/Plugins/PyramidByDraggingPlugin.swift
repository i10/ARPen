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
    
    /**
     The starting point is the point of the pencil where the button was first pressed.
     If this var is nil, there was no initial point
     */
    private var startingPoint: SCNVector3?
    
    ///final box dimensions
    private var finalPyramidWidth: Double?
    private var finalPyramidHeight: Double?
    private var finalPyramidLength: Double?
    
    ///final box position
    private var finalPyriamidPos: SCNVector3?
    
    override init() {
        super.init()
        
        self.pluginImage = UIImage.init(named: "PyramidPlugin")
        self.pluginInstructionsImage = UIImage.init(named: "PyramidPluginInstructions")
        self.pluginIdentifier = "Pyramid"
        self.needsBluetoothARPen = false
    }
    
    override func didUpdateFrame(scene: PenScene, buttons: [Button : Bool]) {
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
                
                self.finalPyramidWidth = Double(pyramidWidth)
                self.finalPyramidHeight = Double(pyramidHeight)
                self.finalPyramidLength = Double(pyramidLength)
                
                // Calculate the center position of the pyramid node
                let pyramidCenterXPosition = scene.pencilPoint.position.x
                let pyramidCenterYPosition = startingPoint.y
                let pyramidCenterZPosition = startingPoint.z + (scene.pencilPoint.position.z - startingPoint.z)/2
                

                pyramidNode.position = SCNVector3.init(pyramidCenterXPosition, pyramidCenterYPosition, pyramidCenterZPosition)
                
                //MAINUPULIERE DIE POS VON AR NODE
                self.finalPyriamidPos = pyramidNode.convertPosition(pyramidNode.boundingBox.min, to: self.currentScene?.drawingNode)
                
                
            } else {
                //if the button is pressed but no startingPoint exists -> first frame with the button pressed. Set current pencil position as the start point
                self.startingPoint = scene.pencilPoint.position
            }
        } else {
            //if the button is not pressed, check if a startingPoint is set -> released button. Reset the startingPoint to nil and set the name of the drawn pyramid to "finished"
            if self.startingPoint != nil
            {
                self.startingPoint = nil
                if let pyramidNode = scene.drawingNode.childNode(withName: "currentDragPyramidNode", recursively: false)
                {
                    //assign a random name to the boxNode for identification in further process
                    pyramidNode.name = randomString(length: 32)
                    //remove "SceneKit" Pyramid
                    pyramidNode.removeFromParentNode()
                    
                    let pyramid = ARPPyramid(width: finalPyramidWidth!, height: finalPyramidHeight!, length: finalPyramidLength!)
                
                    DispatchQueue.main.async {
                        scene.drawingNode.addChildNode(pyramid)
                    }
                    
                    pyramid.localTranslate(by: self.finalPyriamidPos!)
                    pyramid.applyTransform()

                }
            }
        }
    }
}

