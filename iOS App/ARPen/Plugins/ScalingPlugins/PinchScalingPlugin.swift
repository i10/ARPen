//
//  PinchScalingPlugin.swift
//  ARPen
//
//  Created by Andreas RF Dymek on 25.12.20.
//  Copyright © 2020 RWTH Aachen. All rights reserved.
//

import Foundation
import ARKit

class  PinchScalingPlugin: Plugin {
    
    private var scaler: PinchScaler

        
    override init() {
     
        scaler = PinchScaler()
        super.init()
        self.pluginImage = UIImage.init(named: "ScalingPinch")
        self.pluginInstructionsImage = UIImage.init(named: "ScalingPinchInstructions")
        self.pluginIdentifier = "Scaling (Pinch)"
        self.pluginGroupName = "Manipulation"
        self.needsBluetoothARPen = false
        

        
    }
    
    override func activatePlugin(withScene scene: PenScene, andView view: ARSCNView, urManager: UndoRedoManager) {
        super.activatePlugin(withScene: scene, andView: view, urManager: urManager)
        self.scaler.activate(withScene: scene, andView: view, urManager: urManager)
        
    }
    
    override func deactivatePlugin() {
        scaler.deactivate()
        
        super.deactivatePlugin()
    }
    
    override func didUpdateFrame(scene: PenScene, buttons: [Button : Bool]) {

        scaler.update(scene: scene, buttons: buttons)
    }
    

    
}
    
    
    
