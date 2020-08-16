//
//  DateExtensions.swift
//  ARPen
//
//  Created by Jan Benscheid on 19.04.19.
//  Copyright © 2019 RWTH Aachen. All rights reserved.
//

import Foundation

extension Date {
    
    var millisecondsSince1970:Int64 {
            return Int64((self.timeIntervalSince1970 * 1000.0).rounded())
        }
        
        init(milliseconds:Int64) {
            self = Date(timeIntervalSince1970: TimeInterval(milliseconds) / 1000)
        }
    
    static func - (lhs: Date, rhs: Date) -> TimeInterval {
        return lhs.timeIntervalSinceReferenceDate - rhs.timeIntervalSinceReferenceDate
    }
    
}
