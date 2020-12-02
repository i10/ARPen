//
//  PluginManager.swift
//  ARPen
//
//  Created by Felix Wehnert on 16.01.18.
//  Copyright © 2018 RWTH Aachen. All rights reserved.
//

import ARKit

protocol PluginManagerDelegate {
    func penConnected()
    func penFailed()
}

/**
 The PluginManager holds every plugin that is used. Furthermore the PluginManager holds the AR- and PenManager to provide status information about the ARPen.
 
 Additionally, the PluginManager handles all input events (ARPen, touch, alternative cursor) and sends corresponding events to the active plugin.
 */
class PluginManager: ARManagerDelegate, PenManagerDelegate {

    var arManager: ARManager
    var arPenManager: PenManager
    private (set) var buttons: [Button: Bool] = [.Button1: false, .Button2: false, .Button3: false]
    var paintPlugin: PaintPlugin
    var activePlugin: Plugin? {
        willSet {
            //Reset everything
            activePlugin?.deactivatePlugin()
            activePlugin?.pluginManager = nil
            alternativeCursor = nil
            allowPenInput = true
            allowTouchInput = true
            
        }
        didSet {
            activePlugin?.pluginManager = self
            activePlugin?.activatePlugin(withScene: penScene, andView: sceneView)
        }
    }
    
    var plugins: [Plugin]
    var delegate: PluginManagerDelegate?
    var experimentalPluginsStartAtIndex: Int
    
    private (set) var penScene: PenScene
    private (set) var sceneView: ARSCNView
    
    var alternativeCursor: SCNNode? = nil
    var allowPenInput = true
    var allowTouchInput = true
    
    
    private var hitNode: SelectableNode? {
        willSet {
            hitNode?.highlight = false
        }
        didSet {
            hitNode?.highlight = true
        }
    }
    ///True if one button fo the pen is clicked
    private var penButtonIsPressed = false
    var pluginInstructionsCanBeHidden = [Bool]()
    
    /**
     inits every plugin
     */
    init(penScene: PenScene, sceneView: ARSCNView) {
        self.penScene = penScene
        self.sceneView = sceneView
        
        self.arManager = ARManager(scene: self.penScene)
        self.paintPlugin = PaintPlugin()
        self.experimentalPluginsStartAtIndex = 7
        self.plugins = [CubeByDraggingPlugin(), PyramidByDraggingPlugin(), SphereByDraggingPlugin(), CylinderByDraggingPlugin(), CubeByExtractionPlugin(), SweepPluginProfileAndPath(), SweepPluginTwoProfiles(), LoftPlugin(), RevolvePluginProfileAndAxis(), RevolvePluginProfileAndCircle(), RevolvePluginTwoProfiles(), CombinePluginFunction(), CombinePluginSolidHole(), TransformPluginBase(), PenRayScalingPlugin()]
        self.pluginInstructionsCanBeHidden = Array(repeating: true, count: self.plugins.count)
        self.arPenManager = PenManager()
        //self.activePlugin = plugins.first
        self.arManager.delegate = self
        self.arPenManager.delegate = self
        
        //listen to softwarePenButton notifications
        NotificationCenter.default.addObserver(self, selector: #selector(self.softwareButtonEvent(_:)), name: .softwarePenButtonEvent, object: nil)

    }
    
    //Callback from Notification Center. Format of userInfo: ["buttonPressed"] is the button the event is for, ["buttonState"] is the boolean whether the button is pressed or not
     @objc func softwareButtonEvent(_ notification: Notification){
         if let buttonPressed = notification.userInfo?["buttonPressed"] as? Button, let buttonState = notification.userInfo?["buttonState"] as? Bool {
            self.button(buttonPressed, pressed: buttonState)
         }
     }

    
    /**
     This is the callback from ARManager.
     */
    func finishedCalculation() {
        if let plugin = self.activePlugin as? PenDelegate, self.allowPenInput {
//            //add red border to the screen to show when the pen is not tracked
//            DispatchQueue.main.async {
//                if let overlay = self.sceneView.overlaySKScene {
//                    var indicator = overlay.childNode(withName: "markerIndicator")
//                    if indicator == nil {
//                        indicator = SKShapeNode(rect: overlay.frame)
//                        indicator!.name = "markerIndicator"
//                        (indicator as! SKShapeNode).lineWidth = 30
//                        overlay.addChild(indicator!)
//                    }
//                    let isPenImportant = (self.activePlugin is StudyPlugin) && !(self.activePlugin as! StudyPlugin).isPenTipHidden
//                    (indicator as! SKShapeNode).strokeColor = !self.penScene.markerFound && isPenImportant ? UIColor.red : UIColor.clear
//                }
//                
//            }
            
            if penButtonIsPressed {
                plugin.onPenMoved(to: (arManager.scene?.pencilPoint.position)!, clickedButtons: Array(self.buttons.filter { $0.value == true }.keys))
            } else {
                plugin.onIdleMovement(to: (arManager.scene?.pencilPoint.position)!)
            }
        } else if let plugin = self.activePlugin {
            plugin.didUpdateFrame(scene: self.arManager.scene!, buttons: buttons)
        }
    }
    
    func undoPreviousStep() {
        // Todo: Add undo functionality for all plugins.
//        self.paintPlugin.undoPreviousAction()
        if activePlugin is StudyPlugin {
            (activePlugin as! StudyPlugin).repeatTarget()
        }
    }
}


//MARK: PenManager Callbacks (BLE stuff)
/// This extension handles the event management when a button of the ARPen is used.
extension PluginManager {
    
    func button(_ button: Button, pressed: Bool) {
        if !self.allowPenInput { return }
        
        let started = self.buttons[button] != pressed && pressed
        let released = self.buttons[button] != pressed && !pressed
        self.buttons[button] = pressed
        
        //Find pointed object
        let pointerPosition: SCNVector3
        if self.alternativeCursor != nil {
            pointerPosition = self.alternativeCursor!.worldPosition
        } else {
            pointerPosition = arManager.scene!.pencilPoint.position
        }
        
        //Trigger events
        if let penPlugin = self.activePlugin as? PenDelegate {
            var devicePointerMenuIsOpen = false
            if let movingCursorPlugin = self.activePlugin as? MovingCursorPlugin {
                if movingCursorPlugin.arMenu != nil {
                    devicePointerMenuIsOpen = true
                }
            }
            //Check whether an SelectableNode is hit
            let hits = hitTest(pointerPosition: pointerPosition)
            if hits.isEmpty && !devicePointerMenuIsOpen {
                MenuManager.shared.closeMenu()
            } else if !devicePointerMenuIsOpen{
                let hitNode = hits.first?.node as? Selectable
                hitNode?.objectSelected(hitNode!, intersectionAt: (hits.first?.localCoordinates)!, cursor: AREvent(inputType: .ARPen, location: (hitNode as! SCNNode).convertPosition(penScene.pencilPoint.position, from: penScene.rootNode), eventType: started ? .Began : .Ended ))
            }
            
            //Call pen delegates
            if started {
                penPlugin.onPenClickStarted(at: pointerPosition, startedButton: button)
            } else if released {
                penPlugin.onPenClickEnded(at: pointerPosition, releasedButton: button)
            }
        }
        
        //Determine whether on button of the pen is pressed (see finishedCalculation() )
        var oneButtonClicked = false
        buttons.forEach({ oneButtonClicked = oneButtonClicked || $1 })
        penButtonIsPressed = oneButtonClicked
    }
    
    func hitTest(pointerPosition: SCNVector3) -> [SCNHitTestResult] {
        let projectedPencilPosition = sceneView.projectPoint(pointerPosition)
        let projectedCGPoint = CGPoint(x: CGFloat(projectedPencilPosition.x), y: CGFloat(projectedPencilPosition.y))
        return hitTest(pointerPosition: projectedCGPoint)
    }
    
    func hitTest(pointerPosition: CGPoint) -> [SCNHitTestResult] {
        //cast a ray from that position and find the first ARPenNode
        let hitResults = sceneView.hitTest(pointerPosition, options: [SCNHitTestOption.searchMode : SCNHitTestSearchMode.all.rawValue])
        
        return hitResults.filter({$0.node is Selectable}).sorted(by: { (h1, h2) -> Bool in return !(h2.node is ARMenu) })
    }
    
    func connect(successfully: Bool) {
        if successfully {
            self.delegate?.penConnected()
        } else {
            self.delegate?.penFailed()
        }
    }
}

//-------------------------------------------------------------------- MARK: Touch Events


/// This extension handles the event management when touche events were triggered.
extension PluginManager {
    func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        handleTouchEvents(touches, with: event, cursorEvent: .Began)
    }
    
    func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard self.allowTouchInput else { return }
        (self.activePlugin as? TouchDelegate)?.touchesMoved(touches, with: event)
    }
    
    func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        handleTouchEvents(touches, with: event, cursorEvent: .Ended)
    }
    
    private func handleTouchEvents(_ touches: Set<UITouch>, with event: UIEvent?, cursorEvent: AREvent.AREventType) {
        guard self.allowTouchInput else { return }
        
        //Find pointed object
        let hits:[SCNHitTestResult]
        if self.alternativeCursor != nil {
            hits = hitTest(pointerPosition: self.alternativeCursor!.worldPosition)
        } else {
            hits = hitTest(pointerPosition: (touches.first?.location(in: self.sceneView))!)
        }
        
        guard let hitNode = hits.first?.node as? Selectable else {
            MenuManager.shared.closeMenu()
            return
        }
        //Get 3d coordinates on the near plane
        var point = sceneView.unprojectPoint(SCNVector3(touches.first!.location(in: self.sceneView).x, touches.first!.location(in: self.sceneView).y, 0.0))
        
        //transform to hitNode's local coordinate system
        point = (hitNode as! SCNNode).convertPosition(point, from: penScene.rootNode)
        hitNode.objectSelected(hitNode,
                         intersectionAt: (hits.first?.localCoordinates)!,
                         cursor: AREvent(inputType: .Touch,
                                          location: point,
                                          eventType: cursorEvent))
        
        if cursorEvent == .Began {
            (self.activePlugin as? TouchDelegate)?.touchesBegan(touches, with: event)
        } else {
            (self.activePlugin as? TouchDelegate)?.touchesEnded(touches, with: event)
        }
    }
    
    func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard self.allowTouchInput else { return }
        (self.activePlugin as? TouchDelegate)?.touchesCancelled(touches, with: event)
    }
}

//Mark: PenDelegate
/// Handles pen moving events
protocol PenDelegate {
    func onIdleMovement(to position: SCNVector3)
    func onPenClickStarted(at position: SCNVector3, startedButton: Button)
    func onPenMoved(to position: SCNVector3, clickedButtons: [Button])
    func onPenClickEnded(at position: SCNVector3, releasedButton: Button)
}

extension PenDelegate {
    func onIdleMovement(to position: SCNVector3){}
    func onPenClickStarted(at position: SCNVector3, startedButton: Button){}
    func onPenMoved(to position: SCNVector3, clickedButtons: [Button]){}
    func onPenClickEnded(at position: SCNVector3, releasedButton: Button){}
}

//Mark: TouchDelegate
/// Handles pen moving events
protocol TouchDelegate {
    func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?)
    func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?)
    func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?)
    func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?)
}

extension TouchDelegate {
    func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?){}
    func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?){}
    func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?){}
    func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?){}
}
