//
//  MarkerBox.swift
//  ARPen
//
//  Created by Felix Wehnert on 16.01.18.
//  Copyright © 2018 RWTH Aachen. All rights reserved.
//

import SceneKit

/**
 The MarkerBox represents the Box on the ARPen. It simplifies some mathamtics.
 */
class MarkerBox: SCNNode {
    
    private var markerArray: [SCNNode]
    var penLength: Double = 12
    
    /**
     * Describes in which landscape orientation the device is currently hold
     * If the device is hold in portrait orientation, the state keeps in the last landscape state
     */
    private var orientationState: DeviceOrientationState = .HomeButtonRight {
        didSet {
            //For each orientation the pen tip has to be calculated
            calculatePenTip(length: penLength)
        }
    }
    
    override convenience init() {
        self.init(length: UserDefaults.standard.double(forKey: UserDefaultsKeys.penLength.rawValue))
    }
    
    init(length: Double) {
        markerArray = [SCNNode(), SCNNode(), SCNNode(), SCNNode(), SCNNode(), SCNNode()]
        penLength = length
        super.init()
        self.name = "MarkerBox"
        
        //Observe device orientation. If orientation changes rotated() is called
        NotificationCenter.default.addObserver(self, selector: #selector(rotated), name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
        
        //Make pen tip calculation
        calculatePenTip(length: length)
    }
    
    @objc func rotated(){
        if UIDevice.current.orientation.rawValue == 4 {
            orientationState = .HomeButtonLeft
        } else if UIDevice.current.orientation.rawValue == 3 {
            orientationState = .HomeButtonRight
        }
    }
    
    func calculatePenTip(length: Double){
        
        let a: Double = length
        var xs, ys, zs, xl, yl, zl: Double
        
        let angle = (35.3).degreesToRadians
        
        xs = ((cos(angle) * a) + 0.005)/sqrt(2)
        ys = xs
        zs = sin(angle) * a
        zs -= 0.02
        xs *= -1
        ys *= -1
        zs *= -1
        
        xl = (cos(angle) * a)/sqrt(2)
        yl = xl
        zl = sin(angle) * a
        zl += 0.02
        xl *= -1
        yl *= -1
        
        var i = 0
        for marker in markerArray {
            marker.name = "Marker #\(i+1)"
            marker.childNodes.first?.removeFromParentNode()
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
            
            //Invert the coordinates in landscape homebutton left
            if orientationState == .HomeButtonLeft {
                point.position.x *= -1
                point.position.y *= -1
            }
            
            marker.addChildNode(point)
            if !self.childNodes.contains(marker){
                self.addChildNode(marker)
            }
            
            i += 1
        }
    }
    
    /**
     Sets the position and rotation (in euler angles) for a specific ID.
     */
    func set(position: SCNVector3, rotation: SCNVector3, forID id: Int) {
        self.markerArray[id-1].position = position
        self.markerArray[id-1].eulerAngles = rotation
        
        //If orientation is Landscape with home button left we have to revert x and y axis and marker orientation
        if orientationState == .HomeButtonLeft {
            self.markerArray[id-1].position.x *= -1
            self.markerArray[id-1].position.y *= -1
            
            self.markerArray[id-1].eulerAngles.x *= -1
            self.markerArray[id-1].eulerAngles.y *= -1
        }
    }
    
    /**
     Determine the position of the pin point by ONLY considering the specified IDs
     - parameter ids: A list of marker IDs that are used to determine the position
     */
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
    
    private enum DeviceOrientationState {
        case HomeButtonLeft
        case HomeButtonRight
    }
}
