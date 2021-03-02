//
//  PinchScalingPlugin.swift
//  ARPen
//
//  Created by Andreas RF Dymek on 25.12.20.
//  Copyright © 2020 RWTH Aachen. All rights reserved.
//

import Foundation
import ARKit

class TranslationPlugin: Plugin {
    
    private var arranger: Arranger

        
    override init() {
     
        arranger = Arranger()
        super.init()
        self.pluginImage = UIImage.init(named: "Move2DemoPlugin")
        self.pluginInstructionsImage = UIImage.init(named: "DefaultInstructions")
        self.pluginIdentifier = "Translation (Pen)"
        self.pluginGroupName = "Manipulation"
        self.needsBluetoothARPen = false

        
    }
    
    override func activatePlugin(withScene scene: PenScene, andView view: ARSCNView, urManager: UndoRedoManager) {
        super.activatePlugin(withScene: scene, andView: view, urManager: urManager)
        self.arranger.activate(withScene: scene, andView: view, urManager: urManager)
        
    }
    
    override func deactivatePlugin() {
        arranger.deactivate()
        
        super.deactivatePlugin()
    }
    
    override func didUpdateFrame(scene: PenScene, buttons: [Button : Bool]) {
        arranger.update(scene: scene, buttons: buttons)
    }
    

    
}
