//
//  TranslationDemoPlugin.swift
//  ARPen
//
//  Created by Philipp Wacker on 18.03.19.
//  Copyright © 2019 RWTH Aachen. All rights reserved.
//

import Foundation
import ARKit

class TranslationDemoPlugin: Plugin {
    
    static var nodeType : ARPenStudyNode.Type = ARPenBoxNode.self
    
    var sceneConstructionResults : (superNode: SCNNode, studyNodes: [ARPenStudyNode])?
    var boxes : [ARPenStudyNode]?
    var activeTargetBox : ARPenStudyNode? {
        didSet {
            oldValue?.isActiveTarget = false
            self.activeTargetBox?.isActiveTarget = true
            
            //find and activate next drop target that is different from current target
            if self.activeTargetBox != nil {
                var nextDropTarget : ARPenDropTargetNode
                repeat {
                    let randomPosition = Int(arc4random_uniform(UInt32(4)))
                    nextDropTarget = dropTargets[randomPosition]
                } while self.activeDropTarget == nextDropTarget
                self.activeDropTarget = nextDropTarget
            } else {
                self.activeDropTarget = nil
            }
        }
    }
    var indexOfCurrentTargetBox = 0
    
    /**
     The previous point is the point of the pencil one frame before.
     If this var is nil, there was no last point
     */
    private var previousPoint: SCNVector3?
    private var previousButtonState = false
    
    private var selectedBox : ARPenStudyNode? {
        didSet {
            oldValue?.highlighted = false
            selectedBox?.highlighted = true
        }
    }
    
    var gestureRecognizer : UILongPressGestureRecognizer?
    private var locationOfSelectedBoxInCameraCoordinates : SCNVector3?
    
    private var activeDropTarget : ARPenDropTargetNode? {
        didSet {
            oldValue?.removeFromParentNode()
            if let activeDropTarget = self.activeDropTarget {
                self.sceneConstructionResults?.superNode.addChildNode(activeDropTarget)
                //self.currentScene?.drawingNode.addChildNode(activeDropTarget)
            }
        }
    }
    private var dropTargets = [ARPenDropTargetNode(withFloorPosition: SCNVector3Make(0.1238, 0, 0.08695)), ARPenDropTargetNode(withFloorPosition: SCNVector3Make(-0.1238, 0, 0.08695)), ARPenDropTargetNode(withFloorPosition: SCNVector3Make(0.1238, 0, -0.08695)), ARPenDropTargetNode(withFloorPosition: SCNVector3Make(-0.1238, 0, -0.08695))]
    
    override init() {
        super.init()
        
        self.pluginImage = UIImage.init(named: "Move1DemoPlugin")
        self.pluginInstructionsImage = UIImage.init(named: "Move1PluginInstruction")
        self.pluginIdentifier = "Move 1"
        self.needsBluetoothARPen = false
        self.pluginDisabledImage = UIImage.init(named: "TranslationDemoPluginDisabled")
    }
    
    override func didUpdateFrame(scene: PenScene, buttons: [Button : Bool]) {
        
        guard let boxes = self.boxes else {return}
        
        boxes.forEach({
            if $0 != self.selectedBox {
                $0.highlightIfPointInside(point: scene.pencilPoint.convertPosition(SCNVector3Zero, to: self.sceneConstructionResults?.superNode))
            }
        })
        //highlight drop box if target is inside (center part is inside)
        if let activeTargetBox = self.activeTargetBox {
            self.activeDropTarget?.highlightIfPointInside(point: activeTargetBox.position)
        }
        
        
        //update node position if currently a box is selected (per touch)
        if self.gestureRecognizer?.state == .changed, let currentBox = self.selectedBox, let locationInCameraCoordinates = self.locationOfSelectedBoxInCameraCoordinates {
            if let arSceneView = self.currentView, let cameraNode = arSceneView.pointOfView, let currentScene = self.currentScene {
                let newBoxPosition = cameraNode.convertPosition(locationInCameraCoordinates, to: currentScene.drawingNode)
                //print("New Box Position: \(newBoxPosition)")
                currentBox.position = scene.drawingNode.convertPosition(newBoxPosition, to: self.sceneConstructionResults?.superNode)
            }
        }
        
        let pressed = buttons[Button.Button1]! || buttons[Button.Button2]!
        
        if pressed, !self.previousButtonState{
            
            //check if boxes are still to be moved and activate the initial box
            if self.activeTargetBox == nil, self.indexOfCurrentTargetBox < boxes.count {
                self.activeTargetBox = boxes[self.indexOfCurrentTargetBox]
            } else {
                if let arSceneView = self.currentView {
                    //project current pen tip position to screen
                    let projectedPencilPosition = arSceneView.projectPoint(scene.pencilPoint.position)
                    //print(projectedPencilPosition.z)
                    let projectedCGPoint = CGPoint(x: CGFloat(projectedPencilPosition.x), y: CGFloat(projectedPencilPosition.y))
                    
                    //cast a ray from that position and find the first ARPenNode
                    let hitResults = arSceneView.hitTest(projectedCGPoint, options: [SCNHitTestOption.searchMode : SCNHitTestSearchMode.all.rawValue])
                    //check if the first node hit is an arpenBoxNode
                    if let boxHit = hitResults.first?.node as? ARPenStudyNode {
                        self.selectedBox = boxHit
                        //move that ARPenNode to the pen tip if the pencil is not already inside
                        if !boxHit.highlighted {
                            self.selectedBox?.position = scene.pencilPoint.convertPosition(SCNVector3Zero, to: self.sceneConstructionResults?.superNode)
                        }
                        
                    //if the first element hit is not an ARPenBoxNode it could have been the pencil point -> check if the second item hit is an ARPenBoxNode
                    } else if hitResults.count>1, let boxHit = hitResults[1].node as? ARPenStudyNode {
                        self.selectedBox = boxHit
                        //move that ARPenNode to the pen tip
                        self.selectedBox?.position = scene.pencilPoint.convertPosition(SCNVector3Zero, to: self.sceneConstructionResults?.superNode)
                    }
                    
                }
            }
        } else if pressed, self.previousButtonState {
            //move the currently active target
            if let selectedBox = self.selectedBox {
                selectedBox.worldPosition = scene.pencilPoint.worldPosition
            }
        } else if !pressed, self.previousButtonState {
            
            //reset selected box
            self.selectedBox = nil
            
            //check if drop is successfull and then start new target
            if let activeTargetBox = self.activeTargetBox, let activeDropTarget = self.activeDropTarget {
                
                if activeDropTarget.isPointInside(point: activeTargetBox.position) {
                    
                    //self.saveDataEntry()
                    //move target back to original position
                    activeTargetBox.position = activeTargetBox.originalPosition
                    
                    //activate next target
                    self.indexOfCurrentTargetBox += 1
                    if self.indexOfCurrentTargetBox < boxes.count {
                        self.activeTargetBox = boxes[self.indexOfCurrentTargetBox]
                    } else {
                        self.activeTargetBox = nil
                        //print("Done")
                    }
                }
            }
        }
        
        
        self.previousPoint = scene.pencilPoint.position
        self.previousButtonState = pressed
    }
    
    @objc func handleTap(_ sender:UITapGestureRecognizer){
        guard let boxes = self.boxes else {return}
        if sender.state == .began{
            //print("TouchDown recognized")
            let touchPoint = sender.location(in: self.currentView)
            
            guard let sceneView = self.currentView else { return }
            let hitResults = sceneView.hitTest(touchPoint, options: [SCNHitTestOption.searchMode : SCNHitTestSearchMode.all.rawValue] )
            
            if let boxHit = hitResults.first?.node as? ARPenStudyNode {
                self.selectedBox = boxHit
                if let arSceneView = self.currentView, let cameraNode = arSceneView.pointOfView, let currentScene = self.currentScene {
                    self.locationOfSelectedBoxInCameraCoordinates = cameraNode.convertPosition(boxHit.position, from: self.sceneConstructionResults?.superNode)
                }
            }
            
            //check if boxes are still to be moved and activate the initial box
            if self.activeTargetBox == nil, self.indexOfCurrentTargetBox < boxes.count {
                self.activeTargetBox = boxes[self.indexOfCurrentTargetBox]
            }
            //print("Selected Box Position: \(String(describing: self.selectedBox?.position))")
            //print("Location in CameraCoordinates: \(String(describing: self.locationOfSelectedBoxInCameraCoordinates))")
            
        } else if sender.state == .ended {
            //print("Touches Ended")
            self.selectedBox = nil
            //handle drop
            
            //check if drop is successfull and then start new target
            if let activeTargetBox = self.activeTargetBox, let activeDropTarget = self.activeDropTarget {
                if activeDropTarget.isPointInside(point: activeTargetBox.position) {
                    
                    //move target back to original position
                    activeTargetBox.position = activeTargetBox.originalPosition
                    
                    //activate next target
                    self.indexOfCurrentTargetBox += 1
                    if self.indexOfCurrentTargetBox < boxes.count {
                        self.activeTargetBox = boxes[self.indexOfCurrentTargetBox]
                    } else {
                        self.activeTargetBox = nil
                        //print("Done")
                    }
                }
            }
        }
        
    }
    
    override func activatePlugin(withScene scene: PenScene, andView view: ARSCNView){
        super.activatePlugin(withScene: scene, andView: view)
        
//        if (TranslationDemoPlugin.nodeType == ARPenWireBoxNode.self) {
//            TranslationDemoPlugin.nodeType = ARPenBoxNode.self
//        } else {
//            TranslationDemoPlugin.nodeType = ARPenWireBoxNode.self
//        }
        
        self.fillSceneWithCubes(withScene: scene, andView : view)
        
        self.gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(self.handleTap(_:)))
        gestureRecognizer?.minimumPressDuration = 0
        self.currentView?.addGestureRecognizer(gestureRecognizer!)
        self.currentView?.isUserInteractionEnabled = true
    }
    
    
    func fillSceneWithCubes(withScene scene : PenScene, andView view : ARSCNView) {
        let sceneConstructor = ARPenGridSceneConstructor.init()
        self.sceneConstructionResults = sceneConstructor.preparedARPenNodes(withScene: scene, andView: view, andStudyNodeType: TranslationDemoPlugin.nodeType)
        guard let constructionResults = self.sceneConstructionResults else {
            print("scene Constructor did not return boxes")
            return
        }
        self.boxes = constructionResults.studyNodes
        
        scene.drawingNode.addChildNode(constructionResults.superNode)
        
        self.indexOfCurrentTargetBox = 0
        self.activeTargetBox = self.boxes?.first
    }
    
    func lastTrialWasMarkedAsAnOutlier() {
        if self.indexOfCurrentTargetBox > 0 {
            self.indexOfCurrentTargetBox -= 1
        }
        self.activeTargetBox = nil
    }
    
    override func deactivatePlugin() {
        self.activeTargetBox = nil
        //_ = self.currentScene?.drawingNode.childNodes.map({$0.removeFromParentNode()})
        if let constructionResults = self.sceneConstructionResults {
            constructionResults.superNode.removeFromParentNode()
            self.sceneConstructionResults = nil
        }
        self.currentView?.superview?.layer.borderWidth = 0.0
        super.deactivatePlugin()
    }
}
