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
 This plugin is used for PenRayScaling of an object.
 Uses "PenRayScaler" for updating the scale of an object per frame.
 For button where it is *essential* that they are executed once, the code is located here.
*/

class TSRotationPlugin: Plugin {
    
    private var rotator: TSRotator
  

    override init() {
        rotator = TSRotator()
        super.init()
        
        self.pluginImage = UIImage.init(named: "ObjectCreationPlugin")
        //self.pluginInstructionsImage = UIImage.init(named: "ModelingCombineFunctionInstructions")
        self.pluginIdentifier = "TS Rotation"
        self.pluginGroupName = "Rotation"
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
