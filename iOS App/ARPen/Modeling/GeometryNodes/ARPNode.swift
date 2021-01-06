//
//  ARPNode.swift
//  ARPen
//
//  Created by Jan Benscheid on 15.02.19.
//  Copyright © 2019 RWTH Aachen. All rights reserved.
//

import Foundation

/**
 This is the base class for all Nodes which have no underlying representation in Open CASCADE (OCCT), e.g. (currently) `ARPPathNode`s.
*/
public class ARPNode: SCNNode {
    
    var highlighted: Bool = false {
        didSet {
            updateHighlightedState()
        }
    }
    
    var selected: Bool = false {
        didSet {
            updateSelectedState()
        }
    }
    
    var visited: Bool = false {
        didSet {
            updateVisitedState()
        }
    }
    
    func isRootNode() -> Bool {
        return (parent as? ARPNode) == nil
    }
    
    func updateHighlightedState() {}
    
    func updateSelectedState() {}
    
    func updateVisitedState() {}
    
    func applyTransform() {}
}
