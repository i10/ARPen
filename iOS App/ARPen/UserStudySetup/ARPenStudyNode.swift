//
//  ARPenStudyNode.swift
//  ARPen
//
//  Created by Adrian Wagner on 30.07.19.
//  Copyright © 2019 RWTH Aachen. All rights reserved.
//

import Foundation

class ARPenStudyNode : SelectableNode {
    //position and corners are in world coordinates
    let dimension : Float
    
    //initial position to return to, when move completed correctly
    let originalPosition : SCNVector3
    
    var highlighted : Bool = false {
        didSet {
            if highlighted {
                self.geometry?.firstMaterial?.emission.intensity = 0.5
            } else {
                self.geometry?.firstMaterial?.emission.intensity = 0.0
            }
        }
    }
    
    var isActiveTarget = false {
        didSet {
            changeColors()
        }
    }
    
    var inTrialState = false {
        didSet {
            changeColors()
        }
    }
    
    func changeColors(){
        if self.isActiveTarget {
            self.geometry?.firstMaterial?.diffuse.contents = UIColor.green
            self.geometry?.firstMaterial?.emission.contents = UIColor.yellow
        } else if self.inTrialState {
            self.geometry?.firstMaterial?.diffuse.contents = UIColor.orange
            self.geometry?.firstMaterial?.emission.contents = UIColor.magenta
        } else {
            self.geometry?.firstMaterial?.diffuse.contents = UIColor.white
            self.geometry?.firstMaterial?.emission.contents = UIColor.white
        }
    }
    
    required init(withPosition thePosition : SCNVector3, andDimension theDimension : Float) {
        
        self.dimension = theDimension
        self.originalPosition = thePosition
        
        super.init()
        
        self.position = thePosition
    }
    
    // the following property is needed since initWithCoder is overwritten in this class. Since no decoding happens in the function and the decoding is passed on to the superclass, this class supports secure coding as well.
    override public class var supportsSecureCoding: Bool { return true }
    required init?(coder aDecoder: NSCoder) {
        self.dimension = 0.0
        let thePosition = SCNVector3Make(0, 0, 0)
        self.originalPosition = thePosition
        
        super.init(coder: aDecoder)
        
        self.position = thePosition
    }
    
    func distance(ofPoint point : SCNVector3) -> Float {
        return point.distance(vector: self.originalPosition)
    }
    
    func distance(ofPoint point : (dim1 : Float, dim2 : Float), andDim1Borders dim1Borders : (min : Float, max : Float), andDim2Borders dim2Borders : (min: Float, max : Float)) -> Float {
        let dim1Distance = min(abs(point.dim1 - dim1Borders.min), abs(point.dim1 - dim1Borders.max))
        let dim2Distance = min(abs(point.dim2 - dim2Borders.min), abs(point.dim2 - dim2Borders.max))
        
        return sqrtf(powf(dim1Distance, 2) + powf(dim2Distance, 2))
    }
    
    func highlightIfPointInside(point : SCNVector3) {
        if self.isPointInside(point: point) {
            self.highlighted = true
        } else {
            self.highlighted = false
        }
    }
    
    func isPointInside(point : SCNVector3) -> Bool {
        return false
    }
    
    func setShaderModifier(shaderModifiers : [SCNShaderModifierEntryPoint : String]) {
        self.geometry?.shaderModifiers = shaderModifiers
        
        self.childNodes.forEach({
            $0.geometry?.shaderModifiers = shaderModifiers
        })
    }
    
    func setShaderArgument(name : String, value : Float) {
        self.geometry?.firstMaterial?.setValue(value, forKey: name)
        
        self.childNodes.forEach({
            $0.geometry?.firstMaterial?.setValue(value, forKey: name)
        })
    }
}
