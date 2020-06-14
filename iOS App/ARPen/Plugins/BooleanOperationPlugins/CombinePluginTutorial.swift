//
//  CombinePluginTutorial.swift
//  ARPen
//
//  Created by Jan Benscheid on 30.09.19.
//  Copyright © 2019 RWTH Aachen. All rights reserved.
//

import Foundation
import ARKit

/**
This class should demonstrate the exemplary usage of the geometry manipulation code.
*/
class CombinePluginTutorial: ModelingPlugin {

    /// A layer for easier access to the buttons
    private var buttonEvents: ButtonEvents
    /// A "sub-plugin" for selecting and moving objects
    private var arranger: Arranger

    override init() {
        // Initialize arranger
        arranger = Arranger()
        // Initialize button events helper and listen to its press event.
        buttonEvents = ButtonEvents()
        
        super.init()
        
        self.pluginImage = UIImage.init(named: "PaintPlugin")
        self.pluginInstructionsImage = UIImage.init(named: "PaintPluginInstructions")
        self.pluginIdentifier = "Combine (Function)"
        self.needsBluetoothARPen = false
        self.pluginDisabledImage = UIImage.init(named: "ARMenusPluginDisabled")
        
        buttonEvents.didPressButton = self.didPressButton
    }

    /// Called whenever the user switches to the plugin, or returns from the settings with the plugin selected.
    override func activatePlugin(withScene scene: PenScene, andView view: ARSCNView) {
        super.activatePlugin(withScene: scene, andView: view)
        // Forward activation to arranger
        self.arranger.activate(withScene: scene, andView: view)
        
        self.button1Label.text = "Select/Move"
        self.button2Label.text = "Merge"
        self.button3Label.text = "Cut"
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
        case .Button2, .Button3:
            if arranger.selectedTargets.count == 2 {
                // Pop the first two selected targets from the stack to use them for creating a Boolean combination
                guard let b = arranger.selectedTargets.removeFirst() as? ARPGeomNode,
                    let a = arranger.selectedTargets.removeFirst() as? ARPGeomNode else {
                        return
                }
                
                // Geometry creation may take time and should be done asynchronous.
                DispatchQueue.global(qos: .userInitiated).async {
                    // Choose either join/add or cut/subtract depending on the button pressed.
                    if let diff = try? ARPBoolNode(a: a, b: b, operation: button == .Button2 ? .join : .cut) {
                        // Attach the resulting object to the scene synchronous.
                        DispatchQueue.main.async {
                            self.currentScene?.drawingNode.addChildNode(diff)
                            // You don't need to (and must not) delete the `a` and `b`. When creating the Boolean operation, they became children of the `ARPBoolNode` object in order to allow for hierarchical editing.
                            
                        }
                    }
                }
            }
        }
    }
}
