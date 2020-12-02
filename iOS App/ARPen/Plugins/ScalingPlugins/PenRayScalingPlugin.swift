//
//  PenRayScalingPlugin.swift
//  ARPen
//
//  Created by Andreas RF Dymek on 29.11.20.
//  Copyright © 2020 RWTH Aachen. All rights reserved.
//

import Foundation
import ARKit

class PenRayScalingPlugin: ModelingPlugin {
    
    private var scaler: Scaler
    private var buttonEvents: ButtonEvents
    
    override init() {
        buttonEvents = ButtonEvents()
        
        
        scaler = Scaler()
        super.init()
        
        self.pluginImage = UIImage.init(named: "Bool(Function)")
        self.pluginInstructionsImage = UIImage.init(named: "ModelingCombineFunctionInstructions")
        self.pluginIdentifier = "Scaling(PenRay)"
        self.pluginGroupName = "Modeling"
        self.needsBluetoothARPen = false
        
        buttonEvents.didPressButton = self.didPressButton
    }
    
    override func activatePlugin(withScene scene: PenScene, andView view: ARSCNView) {
        super.activatePlugin(withScene: scene, andView: view)
        self.scaler.activate(withScene: scene, andView: view)
        
        self.button1Label.text = "View Bounding Box"
        self.button2Label.text = "Select Corner"
        self.button3Label.text = "Scale"

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
        case .Button2, .Button3:
            if scaler.selectedTargets.count == 2 {
                guard let b = scaler.selectedTargets.removeFirst() as? ARPGeomNode,
                    let a = scaler.selectedTargets.removeFirst() as? ARPGeomNode else {
                        return
                }

                DispatchQueue.global(qos: .userInitiated).async {
                    if let diff = try? ARPBoolNode(a: a, b: b, operation: button == .Button2 ? .join : .cut) {
                        DispatchQueue.main.async {
                            self.currentScene?.drawingNode.addChildNode(diff)

                        }
                    }
                }
            }
        }
    }
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
}
