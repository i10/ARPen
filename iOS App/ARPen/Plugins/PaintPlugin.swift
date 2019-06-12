//
//  PaintPlugin.swift
//  ARPen
//
//  Created by Felix Wehnert on 16.01.18.
//  Copyright © 2018 RWTH Aachen. All rights reserved.
//

import Foundation
import ARKit

class PaintPlugin: Plugin {
    
    var pluginImage : UIImage? = UIImage.init(named: "PaintPlugin")
    var pluginInstructionsImage: UIImage? = UIImage.init(named: "PaintPluginInstructions")
    var pluginIdentifier: String = "Paint"
    var needsBluetoothARPen: Bool = false
    var pluginDisabledImage: UIImage? = UIImage.init(named: "ARMenusPluginDisabled")
    var currentScene : PenScene?
    var currentView: ARSCNView?

    var penColor: UIColor = UIColor.init(red: 0.73, green: 0.12157, blue: 0.8, alpha: 1)
    /**
     The previous point is the point of the pencil one frame before.
     If this var is nil, there was no last point
     */
    private var previousPoint: SCNVector3?
    //collection of currently & last drawn line elements to offer undo
    private var previousDrawnLineNodes: [[SCNNode]]?
    private var currentLine : [SCNNode]?
    private var removedOneLine = false
    
    func didUpdateFrame(scene: PenScene, buttons: [Button : Bool]) {
        guard scene.markerFound else {
            //Don't reset the previous point to avoid disconnected lines if the marker detection failed for some frames
            //self.previousPoint = nil
            return
        }
        let pressed = buttons[Button.Button1]!
        
        if pressed, let previousPoint = self.previousPoint {
            if currentLine == nil {
                currentLine = [SCNNode]()
            }
            let cylinderNode = SCNNode()
            cylinderNode.buildLineInTwoPointsWithRotation(from: previousPoint, to: scene.pencilPoint.position, radius: 0.001, color: penColor)
            cylinderNode.name = "cylinderLine"
            scene.drawingNode.addChildNode(cylinderNode)
            //add last drawn line element to currently drawn line collection
            currentLine?.append(cylinderNode)
        } else if !pressed {
            if let currentLine = self.currentLine {
                self.previousDrawnLineNodes?.append(currentLine)
                self.currentLine = nil
            }
        }
        
        let pressed2 = buttons[Button.Button2]!
        if pressed2, !removedOneLine, let lastLine = self.previousDrawnLineNodes?.last {
            removedOneLine = true
            self.previousDrawnLineNodes?.removeLast()
            //undo last performed line if this is pressed
            for currentNode in lastLine {
                currentNode.removeFromParentNode()
            }
        } else if !pressed2, removedOneLine {
            removedOneLine = false
        }
        
        self.previousPoint = scene.pencilPoint.position
        
    }
    
    func activatePlugin(withScene scene: PenScene, andView view: ARSCNView) {
        self.currentScene = scene
        self.currentView = view
        previousDrawnLineNodes = [[SCNNode]]()
    }
    
    func deactivatePlugin() {
        self.currentScene = nil
        self.currentView = nil
    }
    
}
