//
//  DateExtensions.swift
//  ARPen
//
//  Created by Jan Benscheid on 19.04.19.
//  Copyright © 2019 RWTH Aachen. All rights reserved.
//

import Foundation

extension Date {
    
    static func - (lhs: Date, rhs: Date) -> TimeInterval {
        return lhs.timeIntervalSinceReferenceDate - rhs.timeIntervalSinceReferenceDate
    }
    
}
