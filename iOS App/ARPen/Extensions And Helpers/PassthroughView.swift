//
//  PassthroughView.swift
//  ARPen
//
//  Created by Philipp Wacker on 10.12.19.
//  Copyright © 2019 RWTH Aachen. All rights reserved.
//

// View to let through all touch events that are not on UI elements in this view
// Code taken from: https://medium.com/@nguyenminhphuc/how-to-pass-ui-events-through-views-in-ios-c1be9ab1626b

import UIKit

class PassthroughView: UIView {

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, with: event)
        return view == self ? nil : view
    }
    
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}
