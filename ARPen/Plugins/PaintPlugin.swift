//
//  PaintPlugin.swift
//  ARPen
//
//  Created by Felix Wehnert on 16.01.18.
//  Copyright © 2018 RWTH Aachen. All rights reserved.
//

import Foundation

class PaintPlugin: Plugin {
    
    func didUpdateFrame(scene: PenScene, buttons: [Button : Bool]) {
        
        let pressed = buttons[Button.Button1]!
        
        if pressed, let previousPoint = scene.previousPoint {
            let cylinderNode = SCNNode()
            cylinderNode.buildLineInTwoPointsWithRotation(from: previousPoint, to: scene.pencilPoint.position, radius: 0.01, color: UIColor.red)
            cylinderNode.name = "cylinderLine"
            scene.rootNode.addChildNode(cylinderNode)
        }
        
    }
    
}
