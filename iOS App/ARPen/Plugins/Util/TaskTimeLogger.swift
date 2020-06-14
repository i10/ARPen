//
//  TaskTimeLogger.swift
//  ARPen
//
//  Created by Jan Benscheid on 14.06.19.
//  Copyright © 2019 RWTH Aachen. All rights reserved.
//

import Foundation

class TaskTimeLogger {

    var defaultDict = [String: String]()
    private var startTime: Date?
    private var accumulatedTime: TimeInterval = 0
    private var running: Bool = false
    
    func startUnlessRunning() {
        if self.startTime == nil {
            self.reset()
            self.resume()
        }
    }
    
    func pause() {
        if running, let startTime = self.startTime {
            self.accumulatedTime += Date().timeIntervalSince(startTime)
            self.running = false
        }
    }
    
    func resume() {
        self.startTime = Date()
        self.running = true
    }
    
    func reset() {
        self.accumulatedTime = 0
        self.startTime = nil
        self.running = false
    }
    
    func finish() -> [String:String]  {
        if self.startTime != nil {
            self.pause()
            
            var targetMeasurementDict = self.defaultDict
            targetMeasurementDict["TaskTime"] = String(describing: self.accumulatedTime)
            
            self.reset()
            return targetMeasurementDict
        } else {
            return defaultDict
        }

    }
}
