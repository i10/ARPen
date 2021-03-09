//
//  TSRotationPlugin.swift
//  ARPen
//
//  Created by Andreas RF Dymek on 10.12.20.
//  Copyright © 2020 RWTH Aachen. All rights reserved.
//

import Foundation
import ARKit

/**
 This plugin is used for rotating an object via TouchScreen input.
*/

class TSRotationPlugin: Plugin {
    
    private var rotator: TSRotator
  

    override init() {
        rotator = TSRotator()
        super.init()
        self.pluginImage = UIImage.init(named: "RotationTouchscreen")
        self.pluginInstructionsImage = UIImage.init(named: "TSRotation")
        self.pluginIdentifier = "Rotation (TS)"
        self.pluginGroupName = "Manipulation"
        self.needsBluetoothARPen = false
    }
    
    override func activatePlugin(withScene scene: PenScene, andView view: ARSCNView, urManager: UndoRedoManager) {
        super.activatePlugin(withScene: scene, andView: view, urManager: urManager)
        self.rotator.activate(withScene: scene, andView: view, urManager: urManager)
    }
    
    override func deactivatePlugin() {
        rotator.deactivate()
        
        super.deactivatePlugin()
    }
    
 
    
}
