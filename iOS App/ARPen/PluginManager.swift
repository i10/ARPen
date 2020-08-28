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
    var paintPlugin: PaintPlugin
    var plugins: [Plugin]
    var pluginInstructionsCanBeHidden: [Bool]
    var activePlugin: Plugin?
    var delegate: PluginManagerDelegate?
    var experimentalPluginsStartAtIndex: Int
    
    //var studyPlugin : ClosestPointPainting
    
    /**
     inits every plugin
     */
    init(scene: PenScene) {
        self.paintPlugin = PaintPlugin()
//        self.plugins = [paintPlugin, CubeByDraggingPlugin(), SphereByDraggingPlugin(), CylinderByDraggingPlugin(), PyramidByDraggingPlugin(), CubeByExtractionPlugin(), ARMenusPlugin(), TranslationDemoPlugin(), CombinationPlugin(), RaycastPainting(), ClosestPointPainting(), StudyObjectGeneration()]
        self.plugins = [ClosestPointPainting(), RaycastPainting(), StudyFreehandPainting()]
        self.pluginInstructionsCanBeHidden = Array(repeating: false, count: self.plugins.count)
        self.experimentalPluginsStartAtIndex = 7
        
        
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
    
    func undoPreviousStep() {
        // Todo: Add undo functionality for all plugins.
        
        if (self.activePlugin!.pluginIdentifier == ((ClosestPointPainting()) as Plugin).pluginIdentifier){
            let studyPlugin = ClosestPointPainting()
            studyPlugin.undoPreviousAction()
        }
        else
        if (self.activePlugin!.pluginIdentifier == ((RaycastPainting()) as Plugin).pluginIdentifier){
            let studyPlugin = RaycastPainting()
            studyPlugin.undoPreviousAction()
        }
        else{
            self.paintPlugin.undoPreviousAction()
        }
        
        
    }
}
