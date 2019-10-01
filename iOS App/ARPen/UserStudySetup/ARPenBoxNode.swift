//
//  ARPenBox.swift
//  ARPen
//
//  Created by Philipp Wacker on 30.07.18.
//  Copyright © 2018 RWTH Aachen. All rights reserved.
//

import Foundation

class ARPenBoxNode : ARPenStudyNode {
    
    // observing the position of SCNNode to recalculate corners instead of making an outside code call the function everytime
    override var position : SCNVector3 {
        didSet {
            self.setCorners()
        }
    }
    
    //l = left, r = right, b = back, f = front, d = down, h = high
    var corners : (lbd : SCNVector3, lfd : SCNVector3, rbd : SCNVector3, rfd : SCNVector3, lbh : SCNVector3, lfh : SCNVector3, rbh : SCNVector3, rfh : SCNVector3) = (SCNVector3Make(0, 0, 0),SCNVector3Make(0, 0, 0),SCNVector3Make(0, 0, 0),SCNVector3Make(0, 0, 0),SCNVector3Make(0, 0, 0),SCNVector3Make(0, 0, 0),SCNVector3Make(0, 0, 0),SCNVector3Make(0, 0, 0))

    
    required init(withPosition thePosition : SCNVector3, andDimension theDimension : Float) {

        super.init(withPosition: thePosition, andDimension: theDimension)
        
        let boxGeometry = SCNBox.init(width: CGFloat(self.dimension), height: CGFloat(self.dimension), length: CGFloat(self.dimension), chamferRadius: 0.0)
        self.geometry = boxGeometry
        self.name = "\(thePosition.x), \(thePosition.y), \(thePosition.z)"
        self.geometry?.firstMaterial?.diffuse.contents = UIColor.white
        
        self.geometry?.firstMaterial?.emission.contents = UIColor.white
        self.geometry?.firstMaterial?.emission.intensity = 0.0
        
        self.setCorners()
    }
    
    required init?(coder aDecoder: NSCoder) {
        
        super.init(coder: aDecoder)
        self.setCorners()
    }
    
    override func distance(ofPoint point : SCNVector3) -> Float {
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
    
    override func isPointInside(point : SCNVector3) -> Bool {
        if self.corners.lbd.x <= point.x && point.x <= self.corners.rbd.x
            && self.corners.lbd.y <= point.y && point.y <= self.corners.lbh.y
            && self.corners.lbd.z <= point.z && point.z <= self.corners.lfd.z
        {
            return true
        } else {
            return false
        }
    }
    
    private func setCorners() {
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
}
