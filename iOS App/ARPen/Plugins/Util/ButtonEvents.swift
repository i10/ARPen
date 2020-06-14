//
//  ButtonEvents.swift
//  ARPen
//
//  Created by Jan Benscheid on 15.04.19.
//  Copyright © 2019 RWTH Aachen. All rights reserved.
//

import Foundation

/**
This class adds some convenient functionality to the pen's hardware buttons.
*/
class ButtonEvents {
    
    static let doubleClickMaxDuration = 0.5
    
    var didPressButton: ((Button) -> Void)?
    var didReleaseButton: ((Button) -> Void)?
    var didDoubleClick: ((Button) -> Void)?

    private var pressedThisFrame: [Button : Bool] = [:]
    private var releasedThisFrame: [Button : Bool] = [:]
    private var doubleClickedThisFrame: [Button : Bool] = [:]

    var buttons: [Button : Bool] = [:]
    private var previousButtons: [Button : Bool] = [:]
    private var previousClick: [Button : Date] = [:]
    
    func update(buttons: [Button : Bool]) {
        self.buttons = buttons
        
        for (button, _) in buttons {
            pressedThisFrame[button] = false
            releasedThisFrame[button] = false
            doubleClickedThisFrame[button] = false
            
            if buttonPressed(button) {
                pressedThisFrame[button] = true
                didPressButton?(button)
            } else if buttonReleased(button) {
                releasedThisFrame[button] = true
                didReleaseButton?(button)
                if let prev = previousClick[button], (Date() - prev) <= ButtonEvents.doubleClickMaxDuration {
                    doubleClickedThisFrame[button] = true
                    didDoubleClick?(button)
                }
                previousClick[button] = Date()
            }
        }
        
        previousButtons = buttons
    }
    
    private func buttonPressed(_ button: Button) -> Bool {
        if let n = buttons[button], let p = previousButtons[button] {
            return n && !p
        } else {
            return false
        }
    }
    
    private func buttonReleased(_ button: Button) -> Bool {
        if let n = buttons[button], let p = previousButtons[button] {
            return !n && p
        } else {
            return false
        }
    }
    
    func justPressed(_ button: Button) -> Bool {
        return pressedThisFrame[button] ?? false
    }
    
    func justReleased(_ button: Button) -> Bool {
        return releasedThisFrame[button] ?? false
    }
    
    func justDoubleClicked(_ button: Button) -> Bool {
        return releasedThisFrame[button] ?? false
    }
}
