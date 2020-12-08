//
//  TransformPluginBase.swift
//  ARPen
//
//  Created by Andreas RF Dymek on 10.11.20.
//  Copyright © 2020 RWTH Aachen. All rights reserved.
//

import Foundation
import ARKit

class TransformPluginBase: ModelingPlugin {

    private var buttonEvents: ButtonEvents
    private var arranger: Arranger

    override init() {
        arranger = Arranger()
        buttonEvents = ButtonEvents()
        
        super.init()
        
        self.pluginImage = UIImage.init(named: "Bool(Function)")
        self.pluginInstructionsImage = UIImage.init(named: "ModelingCombineFunctionInstructions")
        self.pluginIdentifier = "Transform Plugin Base"
        self.pluginGroupName = "Modeling"
        self.needsBluetoothARPen = false
        
        buttonEvents.didPressButton = self.didPressButton
    }

    override func activatePlugin(withScene scene: PenScene, andView view: ARSCNView) {
        super.activatePlugin(withScene: scene, andView: view)
        self.arranger.activate(withScene: scene, andView: view)
        
        self.button1Label.text = "Select/Move"
        self.button2Label.text = "SceneKit ↔ OCCT"
        self.button3Label.text = "No Function"
    }
    
    override func deactivatePlugin() {
        arranger.deactivate()
        
        super.deactivatePlugin()
    }
    
    override func didUpdateFrame(scene: PenScene, buttons: [Button : Bool]) {
        buttonEvents.update(buttons: buttons)
        arranger.update(scene: scene, buttons: buttons)
        
        //needed for scaling
        
        
        
    }
    
    func didPressButton(_ button: Button) {
        
        switch button {
        case .Button1:
            break
        case .Button2:
            button2Pressed()
            break
        case .Button3:
            break
                    }
        
    }
    
    func button2Pressed(){
        let scnNode = SCNNode()
        scnNode.geometry = SCNBox(width: 0.2, height: 0.2, length: 0.2, chamferRadius: 0)
        scnNode.position = SCNVector3(0,0,0)
        
        DispatchQueue.main.async {
            self.currentScene?.drawingNode.addChildNode(scnNode)
        }
        
        
        
    }



}


