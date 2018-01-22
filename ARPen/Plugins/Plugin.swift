//
//  Plugin.swift
//  ARPen
//
//  Created by Felix Wehnert on 16.01.18.
//  Copyright © 2018 RWTH Aachen. All rights reserved.
//

import ARKit

/**
 The Plugin protocol. If you want to write a new plugin you must use this protocol.
 */
protocol Plugin {
    
    func didUpdateFrame(scene: PenScene, buttons: [Button: Bool])
    
}
