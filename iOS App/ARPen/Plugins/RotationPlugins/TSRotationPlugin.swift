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

class TSRotationPlugin: ModelingPlugin {
    
    private var rotator: TSRotator
    private var buttonEvents: ButtonEvents

    override init() {
        buttonEvents = ButtonEvents()
        rotator = TSRotator()
        super.init()
        
        self.pluginImage = UIImage.init(named: "ObjectCreationPlugin")
        //self.pluginInstructionsImage = UIImage.init(named: "ModelingCombineFunctionInstructions")
        self.pluginIdentifier = "TS Rotation"
        self.pluginGroupName = "Rotation"
        self.needsBluetoothARPen = false
        
        buttonEvents.didPressButton = self.didPressButton
        
    }
    
    override func activatePlugin(withScene scene: PenScene, andView view: ARSCNView) {
        super.activatePlugin(withScene: scene, andView: view)
        self.rotator.activate(withScene: scene, andView: view)
        
        self.button1Label.text = ""
        self.button2Label.text = ""
        self.button3Label.text = ""

    }
    
    override func deactivatePlugin() {
        rotator.deactivate()
        
        super.deactivatePlugin()
    }
    
    override func didUpdateFrame(scene: PenScene, buttons: [Button : Bool]) {
        buttonEvents.update(buttons: buttons)
       
    }
    
    func didPressButton(_ button: Button) {
        
        switch button {
        case .Button1:
            break
            
        case .Button2:
            break
        
        case .Button3:
            break
        }
    }
    
}
