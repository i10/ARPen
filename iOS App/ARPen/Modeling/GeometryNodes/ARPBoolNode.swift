//
//  ARPBoolNode.swift
//  ARPen
//
//  Created by Jan Benscheid on 15.02.19.
//  Copyright © 2019 RWTH Aachen. All rights reserved.
//

import Foundation

enum BooleanOperation {
    case join, cut, intersect
}

enum BooleanError: Error {
    case operationUnknown
}

/**
 Node for Boolean operations
 */
class ARPBoolNode: ARPGeomNode {
    
    var a: ARPGeomNode
    var b: ARPGeomNode
    
    let operation: BooleanOperation
    
    init(a: ARPGeomNode, b: ARPGeomNode, operation op: BooleanOperation) throws {
        self.a = a
        self.b = b
        self.operation = op
        
        super.init(pivotChild: a)
        self.geometryColor = a.geometryColor

        self.content.addChildNode(a)
        self.content.addChildNode(b)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func build() throws -> OCCTReference {
        
        let ref: OCCTReference?
        
        // The name assignment was needed for the user study.
        switch self.operation {
        case .cut:
            ref = try? OCCTAPI.shared.boolean(from: a.occtReference!, cut: b.occtReference!)
            self.name = "(\(a.name ?? "a")-\(b.name ?? "b"))"
        case .join:
            ref = try? OCCTAPI.shared.boolean(join: a.occtReference!, with: b.occtReference!)
            if (a.name ?? "").count >= (b.name ?? "").count {
                self.name = "(\(a.name ?? "a")+\(b.name ?? "b"))"
            } else {
                self.name = "(\(b.name ?? "b")+\(a.name ?? "a"))"
            }
        case .intersect:
            ref = try? OCCTAPI.shared.boolean(intersect: a.occtReference!, with: b.occtReference!)
            if (a.name ?? "").count >= (b.name ?? "").count {
                self.name = "(\(a.name ?? "a")x\(b.name ?? "b"))"
            } else {
                self.name = "(\(b.name ?? "b")x\(a.name ?? "a"))"
            }
        }
        
        if let r = ref {
            OCCTAPI.shared.setPivotOf(handle: r, pivot: pivotChild.worldTransform)
        }
        
        return ref ?? ""
    }
}
