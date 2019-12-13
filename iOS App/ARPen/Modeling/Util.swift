//
//  Util.swift
//  ARPen
//
//  Created by Jan Benscheid on 15.02.19.
//  Copyright © 2019 RWTH Aachen. All rights reserved.
//

import Foundation
import SceneKit

class Util {
    static func getUUID() -> String {
        return NSUUID().uuidString
    }
}

extension float4x4 {
    init(_ matrix: SCNMatrix4) {
        self.init([
            float4(matrix.m11, matrix.m12, matrix.m13, matrix.m14),
            float4(matrix.m21, matrix.m22, matrix.m23, matrix.m24),
            float4(matrix.m31, matrix.m32, matrix.m33, matrix.m34),
            float4(matrix.m41, matrix.m42, matrix.m43, matrix.m44)
            ])
    }
}

extension float4 {
    init(_ vector: SCNVector4) {
        self.init(vector.x, vector.y, vector.z, vector.w)
    }
    
    init(_ vector: SCNVector3) {
        self.init(vector.x, vector.y, vector.z, 1)
    }
}

extension SCNVector4 {
    init(_ vector: float4) {
        self.init(x: vector.x, y: vector.y, z: vector.z, w: vector.w)
    }
    
    init(_ vector: SCNVector3) {
        self.init(x: vector.x, y: vector.y, z: vector.z, w: 1)
    }
}

extension SCNVector3 {
    init(_ vector: float4) {
        self.init(x: vector.x / vector.w, y: vector.y / vector.w, z: vector.z / vector.w)
    }
}

func * (left: SCNMatrix4, right: SCNVector3) -> SCNVector3 {
    let matrix = float4x4(left)
    let vector = float4(right)
    let result = matrix * vector
    
    return SCNVector3(result)
}

struct Axis {
    var position: SCNVector3 = SCNVector3(0, 0, 0)
    var direction: SCNVector3 = SCNVector3(0, 1, 0)
    
    func projectOnto(point: SCNVector3) -> SCNVector3 {
        return self.position + self.direction*(point - self.position).dot(vector: self.direction)
    }
}
