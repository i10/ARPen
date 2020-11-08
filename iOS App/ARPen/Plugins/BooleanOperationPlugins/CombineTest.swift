//
//  CombineTest.swift
//  ARPen
//
//  Created by Andreas RF Dymek on 31.10.20.
//  Copyright © 2020 RWTH Aachen. All rights reserved.
//

import Foundation
import ARKit

/**
This class should demonstrate the exemplary usage of the geometry manipulation code.
*/
class CombineTest: ModelingPlugin {

    /// A layer for easier access to the buttons
    private var buttonEvents: ButtonEvents
    /// A "sub-plugin" for selecting and moving objects
    private var arranger: ArrangerTest

    override init() {
        // Initialize arranger
        arranger = ArrangerTest()
        // Initialize button events helper and listen to its press event.
        buttonEvents = ButtonEvents()
        
        super.init()
        
        self.pluginImage = UIImage.init(named: "PaintPlugin")
        self.pluginInstructionsImage = UIImage.init(named: "ModelingCombineFunctionInstructions")
        self.pluginIdentifier = "Select/Move/Test"
        self.pluginGroupName = "Modeling"
        self.needsBluetoothARPen = false
        
        buttonEvents.didPressButton = self.didPressButton
    }

    /// Called whenever the user switches to the plugin, or returns from the settings with the plugin selected.
    override func activatePlugin(withScene scene: PenScene, andView view: ARSCNView) {
        super.activatePlugin(withScene: scene, andView: view)
        // Forward activation to arranger
        self.arranger.activate(withScene: scene, andView: view)
        
        self.button1Label.text = "Select/Move"
        self.button2Label.text = "Bounding Box"
    }
    
    override func deactivatePlugin() {
        // Forward deactivation to arranger
        arranger.deactivate()
        
        super.deactivatePlugin()
    }
    
    override func didUpdateFrame(scene: PenScene, buttons: [Button : Bool]) {
        // Forward update event
        buttonEvents.update(buttons: buttons)
        arranger.update(scene: scene, buttons: buttons)
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
