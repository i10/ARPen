//
//  ARPPyramid.swift
//  ARPen
//
//  Created by Andreas RF Dymek on 09.11.20.
//  Copyright © 2020 RWTH Aachen. All rights reserved.
//

import Foundation

class ARPPyramid: ARPGeomNode {
    
    var width: Double = 1
    var height: Double = 1
    var length: Double = 1
    
    override init() {
        super.init()
    }
    
    init(width: Double, height: Double, length: Double) {
        self.width = width
        self.height = height
        self.length = length
        
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func build() throws -> OCCTReference {
        return try OCCTAPI.shared.createPyramid(width: width, height: height, length: length)
    }
}

