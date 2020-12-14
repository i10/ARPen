//
//  SubsequentManipulationPlugin.swift
//  ARPen
//
//  Created by Andreas RF Dymek on 11.12.20.
//  Copyright © 2020 RWTH Aachen. All rights reserved.
//

import Foundation
import ARKit

class SubsequentManipulationPlugin: ModelingPlugin {

    private var buttonEvents: ButtonEvents
    private var manipulator: ModelManipulator
    

    override init() {
        manipulator = ModelManipulator()
        buttonEvents = ButtonEvents()
        
        super.init()

        self.pluginImage = UIImage.init(named: "Bool(Function)")
        self.pluginInstructionsImage = UIImage.init(named: "ModelingCombineFunctionInstructions")
        self.pluginIdentifier = "Manipulation"
        self.pluginGroupName = "Modeling"
        self.needsBluetoothARPen = false
        
        buttonEvents.didPressButton = self.didPressButton
    }

    override func activatePlugin(withScene scene: PenScene, andView view: ARSCNView) {
        super.activatePlugin(withScene: scene, andView: view)
        self.manipulator.activate(withScene: scene, andView: view)
        
        self.button1Label.text = "Select/Deselect"
        self.button2Label.text = "Edit Node"
        self.button3Label.text = ""
    }
    
    override func deactivatePlugin() {
        manipulator.deactivate()
        
        super.deactivatePlugin()
    }
    
    override func didUpdateFrame(scene: PenScene, buttons: [Button : Bool]) {
        buttonEvents.update(buttons: buttons)
        manipulator.update(scene: scene, buttons: buttons)
    }
    
    func didPressButton(_ button: Button) {
        
        switch button {
        case .Button1, .Button2, .Button3:
            break
        }
    }
        
    
}
