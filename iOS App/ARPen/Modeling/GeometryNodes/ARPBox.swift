//
//  ARPCube.swift
//  ARPen
//
//  Created by Jan Benscheid on 18.02.19.
//  Copyright © 2019 RWTH Aachen. All rights reserved.
//

import Foundation

class ARPBox: ARPGeomNode {
    
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
        return try OCCTAPI.shared.createBox(width: width, height: height, length: length)
    }
}
