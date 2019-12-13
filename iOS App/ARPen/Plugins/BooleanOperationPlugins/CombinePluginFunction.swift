//
//  CombinePluginFunction.swift
//  ARPen
//
//  Created by Jan Benscheid on 30.09.19.
//  Copyright © 2019 RWTH Aachen. All rights reserved.
//

import Foundation
import ARKit

class CombinePluginFunction: ModelingPlugin {

    private var buttonEvents: ButtonEvents
    private var arranger: Arranger

    override init() {
        arranger = Arranger()
        buttonEvents = ButtonEvents()
        
        super.init()
        
        self.pluginImage = UIImage.init(named: "PaintPlugin")
        self.pluginInstructionsImage = UIImage.init(named: "PaintPluginInstructions")
        self.pluginIdentifier = "Combine (Function)"
        self.needsBluetoothARPen = false
        self.pluginDisabledImage = UIImage.init(named: "ARMenusPluginDisabled")
        
        buttonEvents.didPressButton = self.didPressButton
    }

    override func activatePlugin(withScene scene: PenScene, andView view: ARSCNView) {
        super.activatePlugin(withScene: scene, andView: view)
        self.arranger.activate(withScene: scene, andView: view)
        
        self.button1Label.text = "Select/Move"
        self.button2Label.text = "Merge"
        self.button3Label.text = "Cut"
    }
    
    override func deactivatePlugin() {
        arranger.deactivate()
        
        super.deactivatePlugin()
    }
    
    override func didUpdateFrame(scene: PenScene, buttons: [Button : Bool]) {
        buttonEvents.update(buttons: buttons)
        arranger.update(scene: scene, buttons: buttons)
    }
    
    func didPressButton(_ button: Button) {
        
        switch button {
        case .Button1:
            break
        case .Button2, .Button3:
            if arranger.selectedTargets.count == 2 {
                guard let b = arranger.selectedTargets.removeFirst() as? ARPGeomNode,
                    let a = arranger.selectedTargets.removeFirst() as? ARPGeomNode else {
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
