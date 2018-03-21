//
//  UserStudyRecordPluginProtocol.swift
//  ARPen
//
//  Created by Philipp Wacker on 13.03.18.
//  Copyright © 2018 RWTH Aachen. All rights reserved.
//

import Foundation

//specifying that a class conforming to this protocol needs to have property for the recordManager (so that it can be set by the viewcontroller when activating the plugin)
protocol UserStudyRecordPluginProtocol {
    var recordManager : UserStudyRecordManager! {get set}
}
