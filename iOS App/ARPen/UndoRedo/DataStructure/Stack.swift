//
//  Stack.swift
//  ARPen
//
//  Created by Andreas RF Dymek on 29.12.20.
//  Copyright © 2020 RWTH Aachen. All rights reserved.
//  inspired by https://www.raywenderlich.com/800-swift-algorithm-club-swift-stack-data-structure

import Foundation

struct Stack<Element> {
    
    fileprivate var array: [Element] = []

    public var count: Int {
      return array.count
    }
    
    public var isEmpty: Bool {
      return array.isEmpty
    }
    
    mutating func push(_ element: Element) {
        array.append(element)
    }
  
    mutating func pop() -> Element? {
        return array.popLast()
    }
  
    func peek() -> Element? {
        return array.last
    }

}
