//
//  ARPRevolution.swift
//  ARPen
//
//  Created by Jan Benscheid on 13.04.19.
//  Copyright © 2019 RWTH Aachen. All rights reserved.
//

import Foundation

/**
 Node for creating a revolved solid.
 */
class ARPRevolution: ARPGeomNode {
    
    var profile: ARPPath
    var axis: ARPPath
    
    // **** For user study ****
    var radiusTop: Float!
    var radiusBottom: Float!
    var angle: Float!
    // ************************

    init(profile: ARPPath, axis: ARPPath) throws {
        
        self.profile = profile
        self.axis = axis
        
        super.init(pivotChild: axis)
        
        self.content.addChildNode(profile)
        self.content.addChildNode(axis)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func build() throws -> OCCTReference {
        
        // Derive rotation axis from first and last point of `axis` path
        var revAxis = Axis()
        revAxis.direction = (axis.points.last!.worldPosition - axis.points.first!.worldPosition).normalized()
        revAxis.position = axis.points.first!.worldPosition
        
        var points = profile.points.map({ ARPPathNode($0.worldPosition, cornerStyle: $0.cornerStyle) })
        points.first!.cornerStyle = .sharp
        points.last!.cornerStyle = .sharp
        // Create additional nodes which are the first- and last node of the profile, projected onto the axis, in order to create a closed volume.
        let top = ARPPathNode(revAxis.projectOnto(point: points.last!.worldPosition))
        let bottom = ARPPathNode(revAxis.projectOnto(point: points.first!.worldPosition))

        // **** For user study ****
        self.radiusTop = points.last!.worldPosition.distance(vector: top.worldPosition)
        self.radiusBottom = points.first!.worldPosition.distance(vector: bottom.worldPosition)
        self.angle = acos(revAxis.direction.y) * 180 / Float.pi
        // ************************

        points.append(top)
        points.insert(bottom, at: 0)
        
        for p in points {
            p.fixed = true
        }
        
        let closedProfile = ARPPath(points: points, closed: true)
        closedProfile.flatten()

        // Adjust revolution axis to newly flattened points
        revAxis.direction = (closedProfile.points.last!.worldPosition - closedProfile.points.first!.worldPosition).normalized()
        revAxis.position = closedProfile.points.first!.worldPosition - revAxis.direction /// It's necessary to shift this point because somehow revolving around a point which exists inside the path yields a construction error

        let ref = try? OCCTAPI.shared.revolve(profile: closedProfile.occtReference!, aroundAxis: revAxis)
        
        if let r = ref {
            OCCTAPI.shared.setPivotOf(handle: r, pivot: pivotChild.worldTransform)
        }
        
        return ref ?? ""
    }
}
