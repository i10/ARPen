//
//  ObjectCreationPlugin.swift
//  ARPen
//
//  Created by Felix Wehnert on 16.01.18.
//  Copyright © 2018 RWTH Aachen. All rights reserved.
//

import Foundation

/**
 The object creation plugin can create a 3d object in space.
 */
class ObjectCreationPlugin: Plugin {
    
    var pluginImage: UIImage? = UIImage.init(named: "Cross")
    var pluginIdentifier: String = "Object Creation"
    
    private var pointArray: [SCNVector3] = []
    private var alreadyAdded = false
    
    func didUpdateFrame(scene: PenScene, buttons: [Button : Bool]) {
        if !buttons[.Button2]!{
            alreadyAdded = false
            return
        }
        if alreadyAdded {
            return
        }
        alreadyAdded = true
        
        pointArray.append(scene.pencilPoint.position)
        
        let maxPoints = 4 // ∆-Time!
        
        if pointArray.count == maxPoints {
            let path = UIBezierPath()
            path.move(to: CGPoint(x: CGFloat(pointArray.first!.x), y: CGFloat(pointArray.first!.z)))
            for vector in pointArray[1...(pointArray.count-1)] {
                let point = CGPoint(x: CGFloat(vector.x), y: CGFloat(vector.z))
                path.addLine(to: point)
            }
            path.close()
            
            let pathRect = path.bounds
            let translate = CGAffineTransform(translationX: -pathRect.midX, y: -pathRect.midY)
            path.apply(translate)
            
            let height = pointArray.last!.y - pointArray.first!.y
            let shape = SCNShape(path: path, extrusionDepth: CGFloat(height))
            let node = SCNNode(geometry: shape)
            node.eulerAngles = SCNVector3(x: .pi/2, y: 0, z: 0)
            node.position = SCNVector3(x: Float(pathRect.midX), y: pointArray.first!.y + height/2, z: Float(pathRect.midY))
            node.name = "createdObject"
            scene.rootNode.addChildNode(node)
            
            pointArray.removeAll()
        }
        
    }
    
}
