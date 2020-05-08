//
//  PositionFilter.swift
//  ARPen
//
//  Created by Philipp Wacker on 08.05.20.
//  Copyright © 2020 RWTH Aachen. All rights reserved.
//

import Foundation

class PositionFilter {
    //specify filter weights
    var alphaValue = 0.5
    var gammaValue = 0.5
    
    //specify previous position & trend
    var previousFilteredPosition : simd_double3?
    var trend : simd_double3?
    
    init(alphaValue:Double, gammaValue:Double){
        self.alphaValue = alphaValue
        self.gammaValue = gammaValue
    }
    
    //smooth the position
    func filteredPositionAfter(newPosition position:simd_double3) -> simd_double3 {
        //check if there are previous positions available, otherwise return the current position
        guard let previousFilteredPosition = self.previousFilteredPosition, let trend = self.trend else {
            return position
        }
        
        //calculate new filtered position
        var firstPartOfEquation = alphaValue * position
        var secondPartOfEquation = (1.0 - alphaValue) * (previousFilteredPosition + trend)
        let newPosition = firstPartOfEquation + secondPartOfEquation
        
        //calculate new trend
        firstPartOfEquation = gammaValue * (newPosition - previousFilteredPosition)
        secondPartOfEquation = (1.0 - gammaValue) * trend
        let newTrend = firstPartOfEquation + secondPartOfEquation
        
        self.previousFilteredPosition = newPosition
        self.trend = newTrend
        
        return newPosition
    }
    
    //convenience method
    func filteredPositionAfter(newPosition position:SCNVector3) -> SCNVector3 {
        let simdVector = simd_double3(position)
        let returnVector = self.filteredPositionAfter(newPosition: simdVector)
        return SCNVector3(returnVector)
    }
    
}
