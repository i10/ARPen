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
    var alphaValue : Float = 0.5
    var gammaValue : Float = 0.5
    
    //specify previous position & trend
    var previousFilteredPosition : SCNVector3?
    var trend : SCNVector3?
    
    var penTipPositionHistory: [SCNVector3] = []
    
    init(alphaValue:Float, gammaValue:Float){
        self.alphaValue = alphaValue
        self.gammaValue = gammaValue
    }
    
    //smooth the position
    func filteredPositionAfter(newPosition position:SCNVector3) -> SCNVector3 {
    
        //return slidingWindowFilteringWith(newPosition: position)
        //return exponentialMovingAverageWith(newPosition: position)
        return doubleExponentialMovingAverageWith(newPosition: position)
        
    }
    
    func slidingWindowFilteringWith(newPosition position : SCNVector3) -> SCNVector3 {
        var penTipPosition = position

        //Average with past n tip positions
        let n = 1
        for pastPenTip in penTipPositionHistory {
            penTipPosition += pastPenTip
        }
        penTipPosition /= Float(penTipPositionHistory.count + 1)
        penTipPositionHistory.append(penTipPosition)

        //Remove latest item if too much items are in penTipPositionHistory
        if penTipPositionHistory.count > n {
            penTipPositionHistory.remove(at: 0)
        }
        
        return penTipPosition
    }
    
    func exponentialMovingAverageWith(newPosition position : SCNVector3) -> SCNVector3 {
        //check if there are previous positions available, otherwise return the current position
        guard let previousFilteredPosition = self.previousFilteredPosition else {
            self.previousFilteredPosition = position
            return position
        }

        //calculate new filtered position (split into two parts since the compiler can't check it otherwise -.-)
        let firstPartOfEquation = alphaValue * position
        let secondPartOfEquation = (1.0 - alphaValue) * previousFilteredPosition
        let newPosition = firstPartOfEquation + secondPartOfEquation
        
        self.previousFilteredPosition = newPosition
        
        return newPosition
    }
    
    func doubleExponentialMovingAverageWith(newPosition position : SCNVector3) -> SCNVector3 {
        //check if there are previous positions available, otherwise return the current position
        guard let previousFilteredPosition = self.previousFilteredPosition, let trend = self.trend else {
            self.previousFilteredPosition = position
            self.trend = SCNVector3Zero
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
}
