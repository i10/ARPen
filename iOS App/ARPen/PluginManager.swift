//
//  PluginManager.swift
//  ARPen
//
//  Created by Felix Wehnert on 16.01.18.
//  Copyright © 2018 RWTH Aachen. All rights reserved.
//

import ARKit

protocol PluginManagerDelegate {
    func arKitInitialiazed()
    func penConnected()
    func penFailed()
}

/**
 The PluginManager holds every plugin that is used. Furthermore the PluginManager holds the AR- and PenManager.
 */
class PluginManager: ARManagerDelegate, PenManagerDelegate {

    var arManager: ARManager
    var arPenManager: PenManager
    var buttons: [Button: Bool] = [.Button1: false, .Button2: false, .Button3: false]
    var plugins: [Plugin] = [PaintPlugin(), CubeByDraggingPlugin(), SphereByDraggingPlugin(), CylinderByDraggingPlugin(), PyramidByDraggingPlugin(), ARMenusPlugin(), TranslationDemoPlugin(), CubeByExtractionPlugin(), CombinationPlugin()]
    var pluginInstructionsCanBeHidden: [Bool] = Array(repeating: false, count: 9)
    var activePlugin: Plugin?
    var delegate: PluginManagerDelegate?
    
    /**
     inits every plugin
     */
    init(scene: PenScene) {
        self.arManager = ARManager(scene: scene)
        self.arPenManager = PenManager()
        self.activePlugin = plugins.first
        self.arManager.delegate = self
        self.arPenManager.delegate = self
    }
    
    /**
     Callback from PenManager
     */
    func button(_ button: Button, pressed: Bool) {
        self.buttons[button] = pressed
    }
    
    /**
     Callback from PenManager
     */
    func connect(successfully: Bool) {
        if successfully {
            self.delegate?.penConnected()
        } else {
            self.delegate?.penFailed()
        }
    }
    
    /**
     Callback form ARCamera
     */
    func didChangeTrackingState(cam: ARCamera) {
        switch cam.trackingState {
        case .normal:
            self.delegate?.arKitInitialiazed()
        default:
            break
        }
    }
    
    /**
     This is the callback from ARManager.
     */
    func finishedCalculation() {
        if let plugin = self.activePlugin {
            plugin.didUpdateFrame(scene: self.arManager.scene!, buttons: buttons)
        }
    }
}
