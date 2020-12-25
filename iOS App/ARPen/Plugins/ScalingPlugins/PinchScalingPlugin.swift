//
//  PinchScalingPlugin.swift
//  ARPen
//
//  Created by Andreas RF Dymek on 25.12.20.
//  Copyright © 2020 RWTH Aachen. All rights reserved.
//

import Foundation
import ARKit

class  PinchScalingPlugin: ModelingPlugin {
    
    private var scaler: PinchScaler
    private var buttonEvents: ButtonEvents
        
    override init() {
        buttonEvents = ButtonEvents()
        scaler = PinchScaler()
        super.init()
        
        self.pluginImage = UIImage.init(named: "Bool(Function)")
        self.pluginInstructionsImage = UIImage.init(named: "ModelingCombineFunctionInstructions")
        self.pluginIdentifier = "Scaling (Pinch)"
        self.pluginGroupName = "Scaling"
        self.needsBluetoothARPen = false
        
        buttonEvents.didPressButton = self.didPressButton
        
    }
    
    override func activatePlugin(withScene scene: PenScene, andView view: ARSCNView) {
        super.activatePlugin(withScene: scene, andView: view)
        self.scaler.activate(withScene: scene, andView: view)
        
        self.button1Label.text = ""
        self.button2Label.text = ""
        self.button3Label.text = ""

    }
    
    override func deactivatePlugin() {
        scaler.deactivate()
        
        super.deactivatePlugin()
    }
    
    override func didUpdateFrame(scene: PenScene, buttons: [Button : Bool]) {
        buttonEvents.update(buttons: buttons)
        scaler.update(scene: scene, buttons: buttons)
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
    
    
    
