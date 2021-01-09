//
//  PenRotationPlugin.swift
//  ARPen
//
//  Created by Andreas RF Dymek on 25.12.20.
//  Copyright © 2020 RWTH Aachen. All rights reserved.
//

import Foundation
import ARKit

/**
 This plugin is used for rotating an object via device input.
*/

class PenRotationPlugin: RotatingPlugin {
    
    private var rotator: PenRotator

    override init() {
        rotator = PenRotator()
        super.init()
        

        self.pluginInstructionsImage = UIImage.init(named: "PenRotation")
        self.pluginIdentifier = "Pen Rotation"
        self.pluginGroupName = "Rotation"
        self.needsBluetoothARPen = false
        
    }
    
    override func activatePlugin(withScene scene: PenScene, andView view: ARSCNView, urManager: UndoRedoManager) {
        super.activatePlugin(withScene: scene, andView: view, urManager: urManager)
        self.rotator.activate(withScene: scene, andView: view, urManager: urManager)
        
        self.button1Label.text = "Select"
        self.button2Label.text = "Hold for Rotation"
        self.button3Label.text = ""

    }
    
    override func deactivatePlugin() {
        rotator.deactivate()
        
        super.deactivatePlugin()
    }
    
    override func didUpdateFrame(scene: PenScene, buttons: [Button : Bool]) {
        rotator.update(scene: scene, buttons: buttons)
    }
    

    
        
    
    
}
