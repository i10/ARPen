//
//  Utilities.swift
//  ARPen
//
//  Created by Krishna Subramanian on 20.07.19.
//  Copyright © 2019 RWTH Aachen. All rights reserved.
//

import Foundation
import simd
import ARKit

extension UIViewController {
    
    func makeRoundedCorners(button: UIButton!) {
        button.layer.masksToBounds = true
        button.layer.cornerRadius = button.frame.width/2
    }
