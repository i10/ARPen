//
//  Plugin.swift
//  ARPen
//
//  Created by Felix Wehnert on 16.01.18.
//  Copyright © 2018 RWTH Aachen. All rights reserved.
//

import ARKit

protocol Plugin {
    
    func didUpdateFrame(scene: PenScene, buttons: [Button: Bool])
    
}
