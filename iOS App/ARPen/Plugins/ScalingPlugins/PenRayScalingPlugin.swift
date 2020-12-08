//
//  PenRayScalingPlugin.swift
//  ARPen
//
//  Created by Andreas RF Dymek on 29.11.20.
//  Copyright © 2020 RWTH Aachen. All rights reserved.
//

import Foundation
import ARKit

/**
 This plugin is used for PenRayScaling of an object.
 Uses "PenRayScaler" for updating the scale of an object per frame.
 For button where it is *essential* that they are executed once, the code is located here.
*/

class PenRayScalingPlugin: ModelingPlugin {
    
    private var scaler: PenRayScaler
    private var buttonEvents: ButtonEvents
    
    //reference for the OCCT mesh
    var occtMesh: ARPGeomNode?
    //reference for the sceneKit represenatation of the OCCT mesh
    var sceneMesh: SCNNode?
    //
    var prevPos: SCNVector3?
    
    
    override init() {
        buttonEvents = ButtonEvents()
        scaler = PenRayScaler()
        super.init()
        
        self.pluginImage = UIImage.init(named: "Bool(Function)")
        self.pluginInstructionsImage = UIImage.init(named: "ModelingCombineFunctionInstructions")
        self.pluginIdentifier = "Scaling(PenRay)"
        self.pluginGroupName = "Modeling"
        self.needsBluetoothARPen = false
        
        buttonEvents.didPressButton = self.didPressButton
        
    }
    
    override func activatePlugin(withScene scene: PenScene, andView view: ARSCNView) {
        super.activatePlugin(withScene: scene, andView: view)
        self.scaler.activate(withScene: scene, andView: view)
        
        self.button1Label.text = "View Bounding Box"
        self.button2Label.text = "Select Corner"
        self.button3Label.text = "Scale"

    }
    
    override func deactivatePlugin() {
        scaler.deactivate()
        
        super.deactivatePlugin()
    }
    
    override func didUpdateFrame(scene: PenScene, buttons: [Button : Bool]) {
        buttonEvents.update(buttons: buttons)
        scaler.update(scene: scene, buttons: buttons)
    }
    
    func didPressButton(_ button: Button) {
        
        switch button {
        case .Button1:
            break
            
        case .Button2:
            cornerSelection()
            break
        
        case .Button3:
            break
        }
    }
    
    ///selects the corner of the bounding box for scaling
    /**
        Selection: If we hover over a corner and press the button, we select the corner for scaling. The mesh is changed out for a sceneKit representation of the OCCT mesh. The pivot is moved for the scale to be relative to the diagonal corner of the mesh.
     */
    func cornerSelection(){
        
        //if pencil Point hovers over a corner
        if scaler.hoverCorner != nil {
            
            //Case: select
            if (scaler.isACornerSelected == false){
                
                let selectedCornerName = scaler.hoverCorner?.name
                
                //get the selected corner
                scaler.selectedCorner = scaler.currentScene?.drawingNode.childNode(withName: selectedCornerName!, recursively: true)
                //color selectedCorner
                scaler.selectedCorner!.geometry?.firstMaterial?.diffuse.contents = UIColor.init(hue: 216/360, saturation: 68/100, brightness: 98/100, alpha: 1.0)
                
                
                occtMesh = (scaler.currentScene?.drawingNode.childNode(withName: "selected", recursively: true)) as? ARPGeomNode
        
                let label = occtMesh!.occtReference
                let scnGeometry = OCCTAPI().occt.sceneKitMesh(of: label)
                let scnNode = SCNNode()
                scnNode.geometry = scnGeometry
                scnNode.name = "scalingSceneKitMesh"
                scnNode.scale = occtMesh!.scale
                scnNode.position = occtMesh!.position
                scnNode.isHidden = false
                        
                prevPos = scnNode.position
                
                //declaring what the sceneMesh is
                sceneMesh = scnNode

                DispatchQueue.main.sync {
                    self.occtMesh!.removeFromParentNode()
                    self.currentScene?.drawingNode.addChildNode(scnNode)
                    self.scaler.showBoundingBoxForGivenMesh(mesh: scnNode)
                }
                        
                let diagonalNode = self.scaler.getDiagonalNode(selectedCorner: self.scaler.selectedCorner!)
                
                /*
                /// Changing the pivot in SceneKit has two oddities:
                /// (1) The node shifts, s.t. the node's pivot stays in the same place relative to the scene
                /// (2) The node's internal coordinate system does not change. Its position does however. Pivot != origin in SceneKit
                /// Shift the pivot to the diagonalCorner so the scaling is relative to a corner.
                */
                        
                scnNode.pivot = SCNMatrix4MakeTranslation((diagonalNode?.position.x)! - scnNode.position.x, (diagonalNode?.position.y)! - scnNode.position.y, (diagonalNode?.position.z)! - scnNode.position.z)
                        
                scnNode.localTranslate(by: diagonalNode!.position - scnNode.position)
                    
                scaler.isACornerSelected = true
                
            }
            
            //Case: deselect
            else
            {
                let diagonalNodeBefore = scaler.getDiagonalNode(selectedCorner: scaler.selectedCorner!)
               
                /*
                /// Changing the pivot in SceneKit has two oddities:
                /// (1) The node shifts, s.t. the node's pivot stays in the same place relative to the scene
                /// (2) The node's internal coordinate system does not change. Its position does however. Pivot != origin in SceneKit
                /// This is resetting the Pivot property to the inital value
                */
                
                DispatchQueue.main.sync {
                    sceneMesh!.position.x -= sceneMesh!.pivot.m41
                    sceneMesh!.position.y -= sceneMesh!.pivot.m42
                    sceneMesh!.position.z -= sceneMesh!.pivot.m43
                    sceneMesh!.pivot = SCNMatrix4Identity
                    
                }
               
                //mincorner of bounding box
                let min = sceneMesh!.convertPosition(sceneMesh!.boundingBox.min, to: self.currentScene?.drawingNode)
                
                //maxcorner of bounding box
                let max = sceneMesh!.convertPosition(sceneMesh!.boundingBox.max, to: self.currentScene?.drawingNode)
                
                //Determine height and width of bounding box
                let height = max.y - min.y
                let width = max.x - min.x
               
                if(diagonalNodeBefore!.name == "lfd"){
                    let diagonalNodeAfter = max - SCNVector3(x: width, y: height, z: 0)
                    let differenceOfPos = diagonalNodeBefore!.position - diagonalNodeAfter
                    sceneMesh!.position += differenceOfPos
                }
                
                if(diagonalNodeBefore!.name == "rbd"){
                    let diagonalNodeAfter = min + SCNVector3(x: width, y: 0, z: 0)
                    let differenceOfPos = diagonalNodeBefore!.position - diagonalNodeAfter
                    sceneMesh!.position += differenceOfPos
 
                }
                if(diagonalNodeBefore!.name == "lbu"){
                    let diagonalNodeAfter = min + SCNVector3(x: 0, y: height, z: 0)
                    let differenceOfPos = diagonalNodeBefore!.position - diagonalNodeAfter
                    sceneMesh!.position += differenceOfPos
 
                }
                if(diagonalNodeBefore!.name == "rbu"){
                    let diagonalNodeAfter = min + SCNVector3(x: width, y: height, z: 0)
                    let differenceOfPos = diagonalNodeBefore!.position - diagonalNodeAfter
                    sceneMesh!.position += differenceOfPos
   
                }
                  
                if(diagonalNodeBefore!.name == "rfd"){
                    let diagonalNodeAfter = max - SCNVector3(x: 0, y: height, z: 0)
                    let differenceOfPos = diagonalNodeBefore!.position - diagonalNodeAfter
                    sceneMesh!.position += differenceOfPos
 
                }
                
                if(diagonalNodeBefore!.name == "lfu"){
                    let diagonalNodeAfter = max - SCNVector3(x: width, y: 0, z: 0)
                    let differenceOfPos = diagonalNodeBefore!.position - diagonalNodeAfter
                    sceneMesh!.position += differenceOfPos

                }
                
                if(diagonalNodeBefore!.name == "rfu"){
                    let diagonalNodeAfter = max
                    let differenceOfPos = diagonalNodeBefore!.position - diagonalNodeAfter
                    sceneMesh!.position += differenceOfPos
  
                }
                
                if(diagonalNodeBefore!.name == "lbd"){
                    let diagonalNodeAfter = min
                    let differenceOfPos = diagonalNodeBefore!.position - diagonalNodeAfter
                    sceneMesh!.position += differenceOfPos

                }

                DispatchQueue.main.sync
                {
                    self.occtMesh?.position = self.sceneMesh!.position
                    if scaler.currentScaleFactor != nil {
                        self.occtMesh?.scale = SCNVector3(self.scaler.currentScaleFactor!, self.scaler.currentScaleFactor!, self.scaler.currentScaleFactor!)
                    }
                    self.occtMesh?.applyTransform()
                    
                    self.sceneMesh!.removeFromParentNode()
                    self.sceneMesh! = SCNNode()
                    self.currentScene?.drawingNode.addChildNode(self.occtMesh!)
                    self.scaler.showBoundingBoxForGivenMesh(mesh: self.occtMesh!)
                   
                }
                
                scaler.selectedCorner = SCNNode()
                scaler.selectedCorner!.name = "generic"
                scaler.isACornerSelected = false
                
            }
        }
    }
    
}
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
