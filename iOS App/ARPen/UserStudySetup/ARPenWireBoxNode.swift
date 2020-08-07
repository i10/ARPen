//
//  ARPenWireBoxNode.swift
//  ARPen
//
//  Created by Adrian Wagner on 30.07.19.
//  Copyright © 2019 RWTH Aachen. All rights reserved.
//

import Foundation

class ARPenWireBoxNode : ARPenStudyNode {
    
    override var highlighted : Bool {
        didSet {
            if highlighted {
                self.childNodes.forEach({
                    $0.geometry?.firstMaterial?.emission.intensity = 0.2
                })
            } else {
                self.childNodes.forEach({
                    $0.geometry?.firstMaterial?.emission.intensity = 0.0
                })
            }
        }
    }
    
    override var isActiveTarget : Bool {
        didSet {
            if self.isActiveTarget {
                self.childNodes.forEach({
                    $0.geometry?.firstMaterial?.diffuse.contents = UIColor.orange
                    $0.geometry?.firstMaterial?.emission.contents = UIColor.orange
                })
            } else {
                self.childNodes.forEach({
                    $0.geometry?.firstMaterial?.diffuse.contents = UIColor.white
                    $0.geometry?.firstMaterial?.emission.contents = UIColor.white
                })
            }
        }
    }
    
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
        
        // create invisible bounding geometry to enable ray casting
        let boundingBoxGeometry = SCNBox.init(width: CGFloat(self.dimension), height: CGFloat(self.dimension), length: CGFloat(self.dimension), chamferRadius: 0.0)
        self.geometry = boundingBoxGeometry
        self.name = "BoundingBox \(thePosition.x), \(thePosition.y), \(thePosition.z)"
        self.geometry?.firstMaterial?.diffuse.contents = UIColor.red
        self.geometry?.firstMaterial?.transparency = 0.0
        
        self.buildWireFrame()
    }
    
    // the following property is needed since initWithCoder is overwritten in this class. Since no decoding happens in the function and the decoding is passed on to the superclass, this class supports secure coding as well.
    override public class var supportsSecureCoding: Bool { return true }
    required init?(coder aDecoder: NSCoder) {
        
        super.init(coder: aDecoder)
        
        self.buildWireFrame()
    }
    
    private func buildWireFrame() {
        self.setCorners()
        
        let wireInfo = [
            // front
            (self.corners.lfd, self.corners.rfd),
            (self.corners.lfh, self.corners.rfh),
            (self.corners.lfd, self.corners.lfh),
            (self.corners.rfd, self.corners.rfh),
            // back
            (self.corners.lbd, self.corners.rbd),
            (self.corners.lbh, self.corners.rbh),
            (self.corners.lbd, self.corners.lbh),
            (self.corners.rbd, self.corners.rbh),
            // front to back
            (self.corners.lfd, self.corners.lbd),
            (self.corners.lfh, self.corners.lbh),
            (self.corners.rfd, self.corners.rbd),
            (self.corners.rfh, self.corners.rbh),
        ]
        
        for info in wireInfo {
            let wire = SCNNode()
            wire.buildLineInTwoPointsWithRotation(from: info.0 - self.position, to: info.1 - self.position, radius: 0.001, color: UIColor.white)
            wire.geometry?.firstMaterial?.emission.contents = UIColor.white
            wire.geometry?.firstMaterial?.emission.intensity = 0.0
            self.addChildNode(wire)
        }
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
    
    override func setShaderModifier(shaderModifiers : [SCNShaderModifierEntryPoint : String]) {
        self.childNodes.forEach({
            $0.geometry?.shaderModifiers = shaderModifiers
        })
    }
    
    override func setShaderArgument(name : String, value : Float) {
        self.childNodes.forEach({
            $0.geometry?.firstMaterial?.setValue(value, forKey: name)
        })
    }
}
