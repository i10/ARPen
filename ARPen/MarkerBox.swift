//
//  MarkerBox.swift
//  ARPen
//
//  Created by Felix Wehnert on 16.01.18.
//  Copyright © 2018 RWTH Aachen. All rights reserved.
//

import SceneKit

class MarkerBox: SCNNode {
    
    var markerArray: [SCNNode]
    
    override init() {
        markerArray = [SCNNode(), SCNNode(), SCNNode(), SCNNode(), SCNNode(), SCNNode()]
        super.init()
        self.name = "MarkerBox"
        
        let a: Double = 0.15
        var xs, ys, zs, xl, yl, zl: Double
        
        let angle = 35.3.degreesToRadians
        
        xs = ((cos(angle)*a)+0.005)/sqrt(2)
        ys = xs
        zs = sin(angle)*a
        zs -= 0.02
        xs *= -1
        ys *= -1
        zs *= -1
        
        xl = (cos(angle)*a)/sqrt(2)
        yl = xl
        zl = sin(angle)*a
        zl += 0.02
        xl *= -1
        yl *= -1
        
        var i = 0
        for marker in markerArray {
            marker.name = "Marker #\(i+1)"
            let point = SCNNode()
            point.name = "Point from #\(i+1)"
            
            switch i {
            case 0:
                point.position = SCNVector3(xs, ys, zs)
            case 1:
                point.position = SCNVector3(xs, ys, zs)
            case 2:
                point.position = SCNVector3(xs, ys, zs)
            case 3:
                point.position = SCNVector3(-xl, yl, zl)
            case 4:
                point.position = SCNVector3(xl, yl, zl)
            case 5:
                point.position = SCNVector3(-xl, yl, zl)
            default:
                break
            }
            
            marker.addChildNode(point)
            self.addChildNode(marker)
            
            i += 1
        }
        
    }
    
    func set(position: SCNVector3, rotation: SCNVector3, forID id: Int) {
        self.markerArray[id-1].position = position
        self.markerArray[id-1].eulerAngles = rotation
    }
    
    func posititonWith(ids: [Int]) -> SCNVector3 {
        var vector = SCNVector3Zero
        
        for id in ids {
            let point = self.markerArray[id-1].childNodes.first!.convertPosition(SCNVector3Zero, to: nil)
            vector += point
        }
        vector /= Float(ids.count)
        return vector
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
}
