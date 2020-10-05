//
//  SphereByDraggingPlugin.swift
//  ARPen
//
//  Created by Krishna Subramanian on 08.06.19.
//  Copyright © 2019 RWTH Aachen. All rights reserved.
//

import Foundation
import ARKit

class SphereByDraggingPlugin: Plugin, UserStudyRecordPluginProtocol {
    //reference to userStudyRecordManager to add new records
    var recordManager: UserStudyRecordManager!
    
    /**
     The starting point is the point of the pencil where the button was first pressed.
     If this var is nil, there was no initial point
     */
    private var startingPoint: SCNVector3?
    
    override init() {
        super.init()
        
        self.pluginImage = UIImage.init(named: "SpherePlugin")
        self.pluginInstructionsImage = UIImage.init(named: "SpherePluginInstructions")
        self.pluginIdentifier = "Sphere"
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
        
        //if the button is pressed -> either set the starting point of the cube (first action) or scale the cube to fit from the starting point to the current point
        if pressed {
            if let startingPoint = self.startingPoint {
                // Use existing sphere node; if one doesn't exist, create it.
                guard let sphereNode = scene.drawingNode.childNode(withName: "currentDragSphereNode", recursively: false) else {
                    let sphereNode = SCNNode()
                    sphereNode.name = "currentDragSphereNode"
                    scene.drawingNode.addChildNode(sphereNode)
                    return
                }
                
                // Calculate the radius of the sphere from ARPen translation.
                let displacementAlongXAxis = scene.pencilPoint.position.x - startingPoint.x
                let displacementAlongYAxis = scene.pencilPoint.position.y - startingPoint.y
                let displacementAlongZAxis = scene.pencilPoint.position.z - startingPoint.z
                
                let sumOfSquaredDisplacements = pow(displacementAlongXAxis, 2) + pow(displacementAlongYAxis, 2) + pow(displacementAlongZAxis, 2)
                let sphereRadius: CGFloat = CGFloat(sqrt(sumOfSquaredDisplacements))
                
                // Get the sphere node geometry (if it is not a SCNSphere, create that with the calculated dimensions)
                guard let sphereNodeGeometry = sphereNode.geometry as? SCNSphere else {
                    sphereNode.geometry = SCNSphere.init(radius: sphereRadius)
                    return
                }
                
                // Set the radius and position of the sphere
                sphereNodeGeometry.radius = sphereRadius
                sphereNode.position = startingPoint
            } else {
                //if the button is pressed but no startingPoint exists -> first frame with the button pressed. Set current pencil position as the start point
                self.startingPoint = scene.pencilPoint.position
            }
        } else {
            //if the button is not pressed, check if a startingPoint is set -> released button. Reset the startingPoint to nil and set the name of the drawn box to "finished"
            if self.startingPoint != nil {
                self.startingPoint = nil
                if let sphereNode = scene.drawingNode.childNode(withName: "currentDragSphereNode", recursively: false), let sphereNodeGeometry = sphereNode.geometry as? SCNSphere {
                    sphereNode.name = "FinishedSphereNode"
                    
                    // Store a new record with the radius of the finished sphere.
                    let sphereDimensionsDict = ["Radius" : String(describing: sphereNodeGeometry.radius)]
                    self.recordManager.addNewRecord(withIdentifier: "SphereFinished", andData: sphereDimensionsDict)
                }
            }
            
        }
        
        
    }
}

