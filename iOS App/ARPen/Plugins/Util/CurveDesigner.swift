//
//  CurveDesigner.swift
//  ARPen
//
//  Created by Jan Benscheid on 15.04.19.
//  Copyright © 2019 RWTH Aachen. All rights reserved.
//

import Foundation
import ARKit

/**
 This class handles the interactive creation of ARPPaths, as this functionality is shared across multiple plugins. An examplary usage can be seen in `SweepPluginTutorial.swift`.
 */
class CurveDesigner {
    
    /// Snapping distance for closing a path
    static let snappingDistance: Float = 0.01
    /// When pressing and holding the button, this is the regular interval in which new nodes are created
    static let minNextPointDistance: Float = 0.02
    
    /// Function called when a new path is started
    var didStartPath: ((ARPPath) -> Void)?
    /// Function called when a new path is finished
    var didCompletePath: ((ARPPath) -> Void)?

    /// The currently edited path
    var activePath: ARPPath? = nil
    
    /// true, if the user just switched between round and sharp corners
    private var blocked: Bool = false
    /// true, if the path is currently being calculated in parallel in the backend, to reduce redundant calculations
    private var busy: Bool = false
    private var scene: PenScene!
    
    private var buttonEvents: ButtonEvents
    
    private var urManager: UndoRedoManager?
    
    /// Guard to avoid inserting multiple nodes in one frame
    private var addedThisFrame: Bool = false

    init() {
        buttonEvents = ButtonEvents()
        buttonEvents.didPressButton = self.didPressButton
        buttonEvents.didReleaseButton = self.didReleaseButton
    }
    
    func activate(scene: PenScene, urManager: UndoRedoManager) {
        self.scene = scene
        self.urManager = urManager
        self.blocked = false
        self.busy = false
        self.activePath = nil
        self.addedThisFrame = false
        
    }
    
   
    func deactivate() {
        for node in self.scene.drawingNode.childNodes {
            
            if ((node as? ARPPath) != nil) {
                let path = node as! ARPPath
                if !path.usedInGeometry {
                    path.removeFromParentNode()
                }
            }
        }
        
        urManager?.removePathActions()
    }
    
    
    
    
    
    
    
    func update(scene: PenScene, buttons: [Button : Bool]) {
        
        self.scene = scene
        addedThisFrame = false
        buttonEvents.update(buttons: buttons)
        
        //if there is an active path
        if let path = activePath {
            
            //if the path is about to be closed, snap the last point to the first
            if path.points.first!.position.distance(vector: scene.pencilPoint.position) < CurveDesigner.snappingDistance && path.points.count > 2 {
                
                //snapping the last point to the first
                path.getNonFixedPoint()?.position = path.points.first!.worldPosition
                
            }
            
            //update the position of the non fixed point
            else {
                path.getNonFixedPoint()?.position = scene.pencilPoint.position
            }
            
            //if ARPen is not found, updates the nonFixed node active status
            if let nonFixed = path.getNonFixedPoint() {
                nonFixed.active = scene.markerFound
            }
            
            //rebuild the entire path
            tryRebuildPreview()
        }
        
        //
        if (buttonEvents.buttons[.Button2]! || buttonEvents.buttons[.Button3]!) && readyForNextPoint() {
            addNode(noNewPath: true)
        }
    }
    
    /// Add a node to either the currently active path, or create a new path if none is active (unless `noNewPath`is set).
    private func addNode(noNewPath: Bool = false) {
        if addedThisFrame {
            return
        }
        addedThisFrame = true
        let cornerStyle = buttonEvents.buttons[.Button2]! ? CornerStyle.sharp : CornerStyle.round
        
        
        //there is no active path, thus we create a new path, first node is created
        if activePath == nil && !noNewPath {
            let path = ARPPath(points: [ARPPathNode(scene.pencilPoint.position, cornerStyle: cornerStyle)], closed: false)
            activePath = path
            scene.drawingNode.addChildNode(path)
            didStartPath?(path)
        }
        
        //there now an active path, second node is created and will change position via update
        if let path = activePath {
            //if the last and first position are snapped and button was pressed, the path is finished
            if pathEndsTouch(path) {
                finishActivePath()
                
            }
            
            //not closed/finished path yet
            else {
                
                let activePoint = path.getNonFixedPoint()
                
                if cornerStyle == activePoint?.cornerStyle
                {
                    activePoint?.fixed = true
                    
                    //the activePoint now is fixed.. its already in the path
                    let nodeAddedAction = AddedNodeToPathAction(scene: scene, path: path, node: activePoint!, curveDesigner: self)
                    self.urManager?.actionDone(nodeAddedAction)
                    
                    //new active point
                    let newNode = ARPPathNode(scene.pencilPoint.position, cornerStyle: cornerStyle)
                    path.appendPoint(newNode)
                
                }
                
                else
                {
                    activePoint?.cornerStyle = cornerStyle
                    blocked = true
                }
            }
        }
    }
    
    
    /*
    func undo() {
        if let path = self.activePath {
            path.removeLastPoint()
            if let last = path.points.last {
                last.fixed = false
            } else {
                self.activePath = nil
            }
        }
    }*/
    
    
    
    func injectUIButtons(_ buttons: [Button : UIButton]) {
        buttons[.Button1]?.setTitle("Finish", for: .normal)
        buttons[.Button2]?.setTitle("Sharp corner", for: .normal)
        buttons[.Button3]?.setTitle("Round corner", for: .normal)
    }
    
    private func didPressButton(_ button: Button) {
        switch button {
        case .Button1:
            finishActivePath()
            
        case .Button2, .Button3:
            addNode()
        }
    }
    
    private func didReleaseButton(_ button: Button) {
        blocked = false
        /*
        switch button {
        case .Button1:
            break
        case .Button2, .Button3:
            if let path = activePath, path.points.count > 2 && path.closed {
                finishActivePath()
            }
        }*/
    }
    
    private func pathEndsTouch(_ path: ARPPath) -> Bool {
        if let nonFixedPoint = path.getNonFixedPoint(), path.points.count > 2 {
            if path.points.first!.worldPosition.distance(vector: nonFixedPoint.worldPosition) < CurveDesigner.snappingDistance {
                return true
            }
        }
        return false
    }
    
    
    //finishing a path

    private func finishActivePath() {
        if let path = activePath {
            if pathEndsTouch(path) {
                path.closed = true
//                path.flatten()
            }
            path.removeNonFixedPoints()
            path.rebuild()
            path.runAction(ARPPath.finalizeAnimation)
            path.finished = true
            activePath = nil
            didCompletePath?(path)
            
            let pathFinishedAction = PathFinishedAction(scene: self.scene, path: path, lastNode: path.points.last!, originallyClosed: path.closed , curveDesigner: self)
            self.urManager?.actionDone(pathFinishedAction)
        }
    }
    
    
    
    func readyForNextPoint() -> Bool {
        if let path = activePath,
            let lastFixed = path.points.last(where: { $0.fixed }),
            let lastFree = path.points.last(where: { !$0.fixed }) {
            if lastFree.worldPosition.distance(vector: lastFixed.worldPosition) < CurveDesigner.minNextPointDistance {
                return false
            }
        }
        return !blocked
    }
    
    func tryRebuildPreview() {
        if !busy, let path = activePath {
            busy = true
            DispatchQueue.global(qos: .userInitiated).async {
                path.rebuild()
                self.busy = false
            }
        }
    }
}
