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
    
    var pluginImage : UIImage? = UIImage.init(named: "TranslationDemoPlugin")
    var pluginInstructionsImage: UIImage? = UIImage.init(named: "DefaultInstructions")
    var pluginIdentifier: String = "Move Objects"
    var needsBluetoothARPen: Bool = false
    var pluginDisabledImage: UIImage? = UIImage.init(named: "TranslationDemoPluginDisabled")
    var currentScene : PenScene?
    var currentView: ARSCNView?
    var finishedView : UILabel?
    
    var sceneConstructionResults : (superNode: SCNNode, boxes: [ARPenBoxNode])?
    var boxes : [ARPenBoxNode]?
    var activeTargetBox : ARPenBoxNode? {
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
    
    private var selectedBox : ARPenBoxNode? {
        didSet {
            oldValue?.hightlighted = false
            selectedBox?.hightlighted = true
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
    
    func didUpdateFrame(scene: PenScene, buttons: [Button : Bool]) {
        
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
            
            //deactivate overlay if boxes are still to be moved
            if self.activeTargetBox == nil, self.indexOfCurrentTargetBox < boxes.count {
                DispatchQueue.main.async {
                    self.finishedView?.removeFromSuperview()
                }
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
                    if let boxHit = hitResults.first?.node as? ARPenBoxNode {
                        self.selectedBox = boxHit
                        //move that ARPenNode to the pen tip if the pencil is not already inside
                        if !boxHit.hightlighted {
                            self.selectedBox?.position = scene.pencilPoint.convertPosition(SCNVector3Zero, to: self.sceneConstructionResults?.superNode)
                        }
                        
                    //if the first element hit is not an ARPenBoxNode it could have been the pencil point -> check if the second item hit is an ARPenBoxNode
                    } else if hitResults.count>1, let boxHit = hitResults[1].node as? ARPenBoxNode {
                        self.selectedBox = boxHit
                        //move that ARPenNode to the pen tip
                        self.selectedBox?.position = scene.pencilPoint.convertPosition(SCNVector3Zero, to: self.sceneConstructionResults?.superNode)
                    }
                    
                }
            }
        } else if pressed, self.previousButtonState {
            //move the currently active target
            if let previousPoint = self.previousPoint, let selectedBox = self.selectedBox {
                let displacementVector = scene.pencilPoint.position - previousPoint
                selectedBox.position = selectedBox.position + scene.pencilPoint.convertVector(displacementVector, to: self.sceneConstructionResults?.superNode)
                selectedBox.setCorners()
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
                        DispatchQueue.main.async {
                            self.finishedView?.text = "Done"
                            if let superview = self.currentView?.superview, let finishedView = self.finishedView {
                                superview.addSubview(finishedView)
                            }
                        }
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
            
            if let boxHit = hitResults.first?.node as? ARPenBoxNode {
                self.selectedBox = boxHit
                if let arSceneView = self.currentView, let cameraNode = arSceneView.pointOfView, let currentScene = self.currentScene {
                    self.locationOfSelectedBoxInCameraCoordinates = cameraNode.convertPosition(boxHit.position, from: self.sceneConstructionResults?.superNode)
                }
            }
            
            //deactivate overlay if boxes are still to be moved
            if self.activeTargetBox == nil, self.indexOfCurrentTargetBox < boxes.count {
                DispatchQueue.main.async {
                    self.finishedView?.removeFromSuperview()
                }
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
                        DispatchQueue.main.async {
                            self.finishedView?.text = "Done"
                            if let superview = self.currentView?.superview, let finishedView = self.finishedView {
                                superview.addSubview(finishedView)
                            }
                        }
                    }
                }
            }
        }
        
    }
    
    func activatePlugin(withScene scene: PenScene, andView view: ARSCNView){

        self.currentScene = scene
        self.currentView = view
        
        self.fillSceneWithCubes(withScene: scene, andView : view)
        
        self.gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(self.handleTap(_:)))
        gestureRecognizer?.minimumPressDuration = 0
        self.currentView?.addGestureRecognizer(gestureRecognizer!)
        self.currentView?.isUserInteractionEnabled = true
    }
    
    
    func fillSceneWithCubes(withScene scene : PenScene, andView view : ARSCNView) {
        let sceneConstructor = ARPenSceneConstructor.init()
        self.sceneConstructionResults = sceneConstructor.preparedARPenBoxNodes(withScene: scene, andView: view)
        guard let constructionResults = self.sceneConstructionResults else {
            print("scene Constructor did not return boxes")
            return
        }
        self.boxes = constructionResults.boxes
        
        scene.drawingNode.addChildNode(constructionResults.superNode)
        
        self.indexOfCurrentTargetBox = 0
        //        self.activeTargetBox = self.boxes?.first
        
        DispatchQueue.main.async {
            self.finishedView = UILabel.init()
            self.finishedView?.text = "Press a button to start"
            self.finishedView?.font = UIFont.preferredFont(forTextStyle: .largeTitle)
            self.finishedView?.textColor = UIColor.yellow
            self.finishedView?.textAlignment = .center
            self.finishedView?.layer.borderWidth = 20.0
            self.finishedView?.layer.borderColor = UIColor.yellow.cgColor
            if let superview = self.currentView?.superview, let finishedView = self.finishedView {
                finishedView.frame.size = CGSize.init(width: 500, height: 300)
                finishedView.center = superview.center
                superview.addSubview(finishedView)
            }
        }
        
    }
    
    func lastTrialWasMarkedAsAnOutlier() {
        if self.indexOfCurrentTargetBox > 0 {
            self.indexOfCurrentTargetBox -= 1
        }
        self.activeTargetBox = nil
        DispatchQueue.main.async {
            self.finishedView?.text = "Press a button to continue"
            if let superview = self.currentView?.superview, let finishedView = self.finishedView {
                superview.addSubview(finishedView)
            }
        }
    }
    
    func deactivatePlugin() {
        self.activeTargetBox = nil
        //_ = self.currentScene?.drawingNode.childNodes.map({$0.removeFromParentNode()})
        if let constructionResults = self.sceneConstructionResults {
            constructionResults.superNode.removeFromParentNode()
            self.sceneConstructionResults = nil
        }
        self.currentScene = nil
        self.finishedView?.removeFromSuperview()
        self.finishedView = nil
        self.currentView?.superview?.layer.borderWidth = 0.0
        self.currentView = nil
    }
}
