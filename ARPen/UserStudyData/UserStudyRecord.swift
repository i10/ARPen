//
//  UserStudyRecord.swift
//  ARPen
//
//  Created by Philipp Wacker on 13.03.18.
//  Copyright © 2018 RWTH Aachen. All rights reserved.
//

import Foundation

struct UserStudyRecord : Codable {
    let creationTime : Date
    //the identifier can be set by the developer to e.g., identify different conditions
    let identifier : String
    //the data array can be set by the developer to include additional information for each record (e.g., individual positions)
    let data : [String:String]
}
