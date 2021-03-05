//
//  Plugin.swift
//  ARPen
//
//  Created by Felix Wehnert on 16.01.18.
//  Copyright © 2018 RWTH Aachen. All rights reserved.
//

import ARKit

/**
 The Plugin structure. If you want to write a new plugin you must inherit from this class.
 */
class Plugin: NSObject {
    
    var pluginImage : UIImage? = UIImage.init(named: "Cross")
    var pluginIdentifier : String = "ARPen Plugin"
    var pluginGroupName : String = "Basic"
    var isExperimentalPlugin = false
    
    //to use a custom UI for your plugin:
    //  1) create a new xib file in the folder "PluginUIs". The name should be that of the plugin
    //  2) set the main view in the xib file as a "PassthroughView"
    //  3) set the background color of the view to clear color
    //  4) to use outlets and actions, set the new plugin class as the file owner in the xib
    //  5) in the init method of your plugin, set "nibNameOfCustomUIView" to the file name of your xib
    // (an example for these steps is shown for the CubeByExtractionPlugin)
    
    //view for custom UI elements. Will be added as a subview to the main view when the plugin is activated.
    //the view has to be a PassthroughView (see helper class) to only react to touches on its UI elements and not block the underlying AR view
    var customPluginUI : PassthroughView?
    //this holds the name of the xib file with the custom UI. If set (e.g. in the init method of the new plugin) this loads the new UI and assigns it to the customPluginUI property
    var nibNameOfCustomUIView : String? = nil {didSet{
        if let nibNameOfCustomUI = nibNameOfCustomUIView, let customView = UINib(nibName: nibNameOfCustomUI, bundle: .main).instantiate(withOwner: self, options: nil).first as? PassthroughView {
            customPluginUI = customView
        }
        }}
    
    var needsBluetoothARPen: Bool = false
    
    var pluginManager: PluginManager?
    
    var currentScene : PenScene?
    var currentView : ARSCNView?
    
    var undoRedoManager: UndoRedoManager?
    
    var pluginInstructionsImage: UIImage? = UIImage.init(named: "DefaultInstructions")
    var pluginDisabledImage: UIImage?
    
    /**
     This method must be implemented by all protocols.
     Params:
     - scene: The current PenScene instance. There you can find a lot state information about the pen.
     - buttons: An array of all buttons and there state. If buttons[.Button1] is true, then the buttons is pressed at the moment.
     */
    func didUpdateFrame(scene: PenScene, buttons: [Button: Bool]){
        
    }
    
    func activatePlugin(withScene scene: PenScene, andView view: ARSCNView, urManager: UndoRedoManager){
        self.undoRedoManager = urManager
        self.currentScene = scene
        self.currentView = view
    }
    
    func deactivatePlugin(){
        self.currentScene = nil
        self.currentView = nil
    }
    
    func undo(){
        self.undoRedoManager?.undo()
    }
    
    func redo(){
        self.undoRedoManager?.redo()
    }
    
    //added a generic function fo random String creation
    //as found on StackOverflow
    func randomString(length: Int) -> String {

        let letters : NSString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let len = UInt32(letters.length)

        var randomString = ""

        for _ in 0 ..< length {
            let rand = arc4random_uniform(len)
            var nextChar = letters.character(at: Int(rand))
            randomString += NSString(characters: &nextChar, length: 1) as String
        }

        return randomString
    }
 
}
