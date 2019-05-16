//
//  ARPenBox.swift
//  ARPen
//
//  Created by Philipp Wacker on 30.07.18.
//  Copyright © 2018 RWTH Aachen. All rights reserved.
//

import Foundation

class ARPenBoxNode : SCNNode {
    //position and corners are in world coordinates
    let dimension : Float
    //l = left, r = right, b = back, f = front, d = down, h = high
    var corners : (lbd : SCNVector3, lfd : SCNVector3, rbd : SCNVector3, rfd : SCNVector3, lbh : SCNVector3, lfh : SCNVector3, rbh : SCNVector3, rfh : SCNVector3) = (SCNVector3Make(0, 0, 0),SCNVector3Make(0, 0, 0),SCNVector3Make(0, 0, 0),SCNVector3Make(0, 0, 0),SCNVector3Make(0, 0, 0),SCNVector3Make(0, 0, 0),SCNVector3Make(0, 0, 0),SCNVector3Make(0, 0, 0))
    
    //initial position to return to, when move completed correctly
    let originalPosition : SCNVector3

    var hightlighted : Bool = false {
        didSet {
            if hightlighted {
                self.geometry?.firstMaterial?.emission.intensity = 1.0
            } else {
                self.geometry?.firstMaterial?.emission.intensity = 0.0
            }
        }
    }
    
    var isActiveTarget = false {
        didSet {
            if self.isActiveTarget {
                self.geometry?.firstMaterial?.diffuse.contents = UIColor.green
                self.geometry?.firstMaterial?.emission.contents = UIColor.yellow
            } else {
                self.geometry?.firstMaterial?.diffuse.contents = UIColor.white
                self.geometry?.firstMaterial?.emission.contents = UIColor.white
            }
        }
    }
    
    init(withPosition thePosition : SCNVector3, andDimension theDimension : Float) {
        
        self.dimension = theDimension
        self.originalPosition = thePosition
        
        super.init()
        
        let boxGeometry = SCNBox.init(width: CGFloat(self.dimension), height: CGFloat(self.dimension), length: CGFloat(self.dimension), chamferRadius: 0.0)
        self.geometry = boxGeometry
        self.position = thePosition
        self.name = "\(thePosition.x), \(thePosition.y), \(thePosition.z)"
        self.geometry?.firstMaterial?.diffuse.contents = UIColor.white
        
        self.geometry?.firstMaterial?.emission.contents = UIColor.white
        self.geometry?.firstMaterial?.emission.intensity = 0.0
        
        self.setCorners()
    }
    
    required init?(coder aDecoder: NSCoder) {
        self.dimension = 0.0
        let thePosition = SCNVector3Make(0, 0, 0)
        self.originalPosition = thePosition
        
        super.init(coder: aDecoder)
        self.setCorners()
    }
    
    func setCorners() {
        let halfDimension = self.dimension/2
        let thePosition = self.position
        
        self.corners.lbd = SCNVector3Make(thePosition.x - halfDimension, thePosition.y - halfDimension, thePosition.z - halfDimension)
        self.corners.lfd = SCNVector3Make(thePosition.x - halfDimension, thePosition.y - halfDimension, thePosition.z + halfDimension)
        self.corners.rbd = SCNVector3Make(thePosition.x + halfDimension, thePosition.y - halfDimension, thePosition.z - halfDimension)
        self.corners.rfd = SCNVector3Make(thePosition.x + halfDimension, thePosition.y - halfDimension, thePosition.z + halfDimension)
        self.corners.lbh = SCNVector3Make(thePosition.x - halfDimension, thePosition.y + halfDimension, thePosition.z - halfDimension)
        self.corners.lfh = SCNVector3Make(thePosition.x - halfDimension, thePosition.y + halfDimension, thePosition.z + halfDimension)
        self.corners.rbh = SCNVector3Make(thePosition.x + halfDimension, thePosition.y + halfDimension, thePosition.z - halfDimension)
        self.corners.rfh = SCNVector3Make(thePosition.x + halfDimension, thePosition.y + halfDimension, thePosition.z + halfDimension)
    }
    
    func distance(ofPoint point : SCNVector3) -> Float {
        switch (point.x, point.y, point.z) {
        //inside the box
        case (self.corners.lbd.x...self.corners.rbd.x, self.corners.lbd.y...self.corners.lbh.y, self.corners.lbd.z...self.corners.lfd.z):
            return 0
        //right of left of the box
        case (_, self.corners.lbd.y...self.corners.lbh.y, self.corners.lbd.z...self.corners.lfd.z):
            return min(abs(point.x - self.corners.lbd.x), abs(point.x - self.corners.rbd.x))
        //over or under the box
        case (self.corners.lbd.x...self.corners.rbd.x, _, self.corners.lbd.z...self.corners.lfd.z):
            return min(abs(point.y - self.corners.lbd.y), abs(point.y - self.corners.lbh.y))
        //in front or behind of the box
        case (self.corners.lbd.x...self.corners.rbd.x, self.corners.lbd.y...self.corners.lbh.y, _):
            return min(abs(point.z - self.corners.lbd.z), abs(point.z - self.corners.lfd.z))
        //depth is within the range
        case (_, _, self.corners.lbd.z...self.corners.lfd.z):
            return distance(ofPoint: (point.x, point.y), andDim1Borders: (self.corners.lbd.x, self.corners.rbd.x), andDim2Borders: (self.corners.lbd.y, self.corners.lbh.y))
        //height is within the range
        case (_, self.corners.lbd.y...self.corners.lbh.y, _):
            return distance(ofPoint: (point.x, point.z), andDim1Borders: (self.corners.lbd.x, self.corners.rbd.x), andDim2Borders: (self.corners.lbd.z, self.corners.lfd.z))
        //width is within the range
        case (self.corners.lbd.x...self.corners.rbd.x, _, _):
            return distance(ofPoint: (point.y, point.z), andDim1Borders: (self.corners.lbd.y, self.corners.lbh.y), andDim2Borders: (self.corners.lbd.z, self.corners.lfd.z))
        default:
            let xDistance = min(abs(point.x - self.corners.lbd.x), abs(point.x - self.corners.rbd.x))
            let yDistance = min(abs(point.y - self.corners.lbd.y), abs(point.y - self.corners.lbh.y))
            let zDistance = min(abs(point.z - self.corners.lbd.z), abs(point.z - self.corners.lfd.z))
            
            return sqrtf(powf(xDistance, 2) + powf(yDistance, 2) + powf(zDistance, 2))
        }
    }
    
    func distance(ofPoint point : (dim1 : Float, dim2 : Float), andDim1Borders dim1Borders : (min : Float, max : Float), andDim2Borders dim2Borders : (min: Float, max : Float)) -> Float {
        let dim1Distance = min(abs(point.dim1 - dim1Borders.min), abs(point.dim1 - dim1Borders.max))
        let dim2Distance = min(abs(point.dim2 - dim2Borders.min), abs(point.dim2 - dim2Borders.max))
        
        return sqrtf(powf(dim1Distance, 2) + powf(dim2Distance, 2))
    }
    
    func highlightIfPointInside(point : SCNVector3) {
        if self.isPointInside(point: point) {
            self.hightlighted = true
        } else {
            self.hightlighted = false
        }
    }
    
    func isPointInside(point : SCNVector3) -> Bool {
        if self.corners.lbd.x <= point.x && point.x <= self.corners.rbd.x
            && self.corners.lbd.y <= point.y && point.y <= self.corners.lbh.y
            && self.corners.lbd.z <= point.z && point.z <= self.corners.lfd.z
        {
            return true
        } else {
            return false
        }
    }
}
