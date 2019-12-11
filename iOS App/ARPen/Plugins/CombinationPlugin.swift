//
//  CombinationPlugin.swift
//  ARPen
//
//  Created by Philipp Wacker on 15.08.18.
//  Copyright © 2018 RWTH Aachen. All rights reserved.
//

import Foundation
import ARKit

class CombinationPlugin: Plugin {
    
    var pluginImage : UIImage? = UIImage.init(named: "Move2DemoPlugin")
    var pluginInstructionsImage: UIImage? = UIImage.init(named: "Move2PluginInstruction")
    var pluginIdentifier: String = "Move 2"
    var needsBluetoothARPen: Bool = true
    var pluginDisabledImage: UIImage? = UIImage.init(named: "TranslationDemoPluginDisabled")
    var currentScene : PenScene?
    var currentView: ARSCNView?
    
    var customPluginUI : PassthroughView?
    
    var sceneConstructionResults : (superNode: SCNNode, studyNodes: [ARPenStudyNode])?
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
    
    var gestureRecognizer : UILongPressGestureRecognizer?
    
    /**
     The previous point is the point of the pencil one frame before.
     If this var is nil, there was no last point
     */
    private var previousPoint: SCNVector3?
    private var previousButtonState = false
    
    private var selectedBox : ARPenBoxNode? {
        didSet {
            oldValue?.highlighted = false
            selectedBox?.highlighted = true
        }
    }
    private var locationOfSelectedBoxInCameraCoordinates : SCNVector3?
    
    private var activeDropTarget : ARPenDropTargetNode? {
        didSet {
            oldValue?.removeFromParentNode()
            if let activeDropTarget = self.activeDropTarget {
                self.sceneConstructionResults?.superNode.addChildNode(activeDropTarget)
            }
        }
    }
    private var dropTargets = [ARPenDropTargetNode(withFloorPosition: SCNVector3Make(0.1238, 0, 0.08695)), ARPenDropTargetNode(withFloorPosition: SCNVector3Make(-0.1238, 0, 0.08695)), ARPenDropTargetNode(withFloorPosition: SCNVector3Make(0.1238, 0, -0.08695)), ARPenDropTargetNode(withFloorPosition: SCNVector3Make(-0.1238, 0, -0.08695))]
    
    func didUpdateFrame(scene: PenScene, buttons: [Button : Bool]) {
        
        guard scene.markerFound else {
            //self.previousPoint = nil
            return
        }
        
        guard let boxes = self.boxes else {return}
        
        boxes.forEach({
            $0.highlightIfPointInside(point: scene.pencilPoint.convertPosition(SCNVector3Zero, to: self.sceneConstructionResults?.superNode))
        })
        //leave selected box highlighted, if it is currently set
        self.selectedBox?.highlighted = true
        
        //highlight drop box if target is inside (center part is inside)
        if let activeTargetBox = self.activeTargetBox {
            self.activeDropTarget?.highlightIfPointInside(point: activeTargetBox.position)
        }
        
        let pressed = buttons[Button.Button1]! || buttons[Button.Button2]!
        
        if pressed, !self.previousButtonState{
            
            //set selected box if pen is currently inside a box
            self.selectedBox?.position = scene.pencilPoint.position
            
        } else if pressed, self.previousButtonState {
            //move the currently active target
            if let previousPoint = self.previousPoint, let selectedBox = self.selectedBox {
                // let displacementVector = scene.pencilPoint.position - previousPoint
                // selectedBox.position = selectedBox.position + displacementVector
                selectedBox.position = sceneConstructionResults!.superNode.convertPosition(scene.pencilPoint.position, from: scene.drawingNode)
                selectedBox.highlighted = true
            }
            
            
        } else if !pressed, self.previousButtonState {
            
            //reset selected box
            self.selectedBox?.highlighted = false
            self.selectedBox = nil
            
            
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
                self.selectedBox?.highlighted = true
            }
            
            //deactivate overlay if boxes are still to be moved
            if self.activeTargetBox == nil, self.indexOfCurrentTargetBox < boxes.count {
                self.activeTargetBox = boxes[self.indexOfCurrentTargetBox]
            }
            //print("Selected Box Position: \(String(describing: self.selectedBox?.position))")
            //print("Location in CameraCoordinates: \(String(describing: self.locationOfSelectedBoxInCameraCoordinates))")
            
        } else if sender.state == .ended {
//            //print("Touches Ended")
//            //handle drop
//            //check if drop is successfull and then start new target
//            if let activeTargetBox = self.activeTargetBox {
//
//                if activeTargetBox.distance(ofPoint: SCNVector3Make(0, 0, 0)) < 0.02 {
//
//                    //self.saveDateEntry(withTarget: activeTargetBox, inScene: scene)
//
//                    //move target back to original position
//                    activeTargetBox.position = activeTargetBox.originalPosition
//
//                    //activate next target
//                    self.indexOfCurrentTargetBox += 1
//                    if self.indexOfCurrentTargetBox < boxes.count {
//                        self.activeTargetBox = boxes[self.indexOfCurrentTargetBox]
//                    } else {
//                        self.activeTargetBox = nil
//                        print("Done")
//                        DispatchQueue.main.async {
//                            self.finishedView?.text = "Done"
//                            if let superview = self.currentView?.superview, let finishedView = self.finishedView {
//                                superview.addSubview(finishedView)
//                            }
//                        }
//                    }
//                }
//            }
            //if no button on the pen is pressed, deselect the object
            if self.previousButtonState == false {
                //reset selected box
                self.selectedBox?.highlighted = false
                self.selectedBox = nil
                
            }
            
        }
        
    }
    
    
    func activatePlugin(withScene scene: PenScene, andView view: ARSCNView){
        
        self.currentScene = scene
        self.currentView = view
        
        self.fillSceneWithCubes(withScene: scene, andView : view)
        
        self.activeTargetBox = nil
        
        self.gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(self.handleTap(_:)))
        gestureRecognizer?.minimumPressDuration = 0
        self.currentView?.addGestureRecognizer(gestureRecognizer!)
        self.currentView?.isUserInteractionEnabled = true
        
    }
    
    func fillSceneWithCubes(withScene scene : PenScene, andView view : ARSCNView) {
        let sceneConstructor = ARPenGridSceneConstructor.init()
        self.sceneConstructionResults = sceneConstructor.preparedARPenNodes(withScene: scene, andView: view, andStudyNodeType: ARPenBoxNode.self)
        guard let constructionResults = self.sceneConstructionResults else {
            print("scene Constructor did not return boxes")
            return
        }
        self.boxes = constructionResults.studyNodes as? [ARPenBoxNode]
        
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
    
    
    
    func deactivatePlugin() {
        self.activeTargetBox = nil
        //_ = self.currentScene?.drawingNode.childNodes.map({$0.removeFromParentNode()})
        if let constructionResults = self.sceneConstructionResults {
            constructionResults.superNode.removeFromParentNode()
            self.sceneConstructionResults = nil
        }
        self.currentScene = nil
        self.currentView?.superview?.layer.borderWidth = 0.0
        
        if let gestureRecognizer = self.gestureRecognizer {
            self.currentView?.removeGestureRecognizer(gestureRecognizer)
        }
        
        self.currentView = nil
    }
    
}


