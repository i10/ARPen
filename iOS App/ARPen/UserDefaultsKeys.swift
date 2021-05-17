//
//  UserDefaultsKeys.swift
//  ARPen
//
//  Created by Felix Wehnert on 01.02.18.
//  Copyright © 2018 RWTH Aachen. All rights reserved.
//

import Foundation

enum UserDefaultsKeys: String {
    case penLength, arPenName, arPenModel
}

// r is used for redesigned models
// CHIARPen and laserMesseARPen shall always be detected. Therfore, there is no need to save them here
// https://stackoverflow.com/questions/39305150/accessing-a-string-enum-by-index/53693227
enum ARPenModelKeys: Int, CaseIterable {
    case original, rTop, rBack, rFront, rBackTop, rBackFront, rTopFront, rBackFrontSmall
    
    static let mapper: [ARPenModelKeys: String] = [
        .original: "Original",
        .rTop: "Top (recommended)",
        .rBack: "Back",
        .rFront: "Front",
        .rBackTop: "BackTop",
        .rBackFront: "BackFront",
        .rTopFront: "TopFront",
        .rBackFrontSmall: "BackFrontSmall"
    ]
    
    var string: String {
        return ARPenModelKeys.mapper[self]!
    }
}
