//
//  OCCTAPI.swift
//  ARPen
//
//  Created by Jan Benscheid on 08.02.19.
//  Copyright © 2019 Jan Benscheid. All rights reserved.
//

import Foundation
import SceneKit

typealias OCCTReference = String

enum OCCTError: Error {
    case couldNotCreateGeometry
}

/**
 This class is the Swift API to the low-level geometry manipulation code. Its main purpose is to convert between C types and Swift types.
 Unless a new functionality is needed, I suggest to use the functions provided in this class for all geometry manipulations.
 */
class OCCTAPI {
    
    static let shared = OCCTAPI()
    
    let occt:OCCT = OCCT()
    
    func createSphere(radius:Double) throws -> OCCTReference {
        if let cString = occt.createSphere(radius) {
            let ref = OCCTReference(cString: cString)
            return ref
        } else {
            throw OCCTError.couldNotCreateGeometry
        }
    }
    
    func createBox(width:Double, height:Double, length:Double) throws -> OCCTReference {
        if let cString = occt.createBox(width, height: height, length: length) {
            let ref = OCCTReference(cString: cString)
            return ref
        } else {
            throw OCCTError.couldNotCreateGeometry
        }
    }
    
    func createPyramid(width:Double, height:Double, length:Double) throws -> OCCTReference {
        if let cString = occt.createPyramid(width, height: height, length: length){
            let ref = OCCTReference(cString: cString)
            return ref
        } else {
            throw OCCTError.couldNotCreateGeometry
        }
    }

    func createCylinder(radius:Double, height:Double) throws -> OCCTReference {
        if let cString = occt.createCylinder(radius, height: height) {
            let ref = OCCTReference(cString: cString)
            return ref
        } else {
            throw OCCTError.couldNotCreateGeometry
        }
    }
    
    func createPath(points:[SCNVector3], corners:[CornerStyle], closed:Bool) throws -> OCCTReference {
        if let cString = occt.createPath(points, length:Int32(points.count), corners: corners.map({ $0.rawValue }), closed:closed) {
            let ref = OCCTReference(cString: cString)
            return ref
        } else {
            throw OCCTError.couldNotCreateGeometry
        }
    }
    
    func boolean(from a: OCCTReference, cut b: OCCTReference) throws -> OCCTReference {
        if let difference = occt.booleanCut(a, subtract: b) {
            let ref = OCCTReference(cString: difference)
            return ref
        } else {
            throw OCCTError.couldNotCreateGeometry
        }
    }
    
    func boolean(join a: OCCTReference, with b: OCCTReference) throws -> OCCTReference {
        if let sum = occt.booleanJoin(a, with: b) {
            let ref = OCCTReference(cString: sum)
            return ref
        } else {
            throw OCCTError.couldNotCreateGeometry
        }
    }
    
    func boolean(intersect a: OCCTReference, with b: OCCTReference) throws -> OCCTReference {
        if let sum = occt.booleanIntersect(a, with: b) {
            let ref = OCCTReference(cString: sum)
            return ref
        } else {
            throw OCCTError.couldNotCreateGeometry
        }
    }
    
    func sweep(profile: OCCTReference, path: OCCTReference) throws -> OCCTReference {
        if let sum = occt.sweep(profile, along: path) {
            let ref = OCCTReference(cString: sum)
            return ref
        } else {
            throw OCCTError.couldNotCreateGeometry
        }
    }
    
    func revolve(profile: OCCTReference, aroundAxis: Axis) throws -> OCCTReference {
        if let sum = occt.revolve(profile, aroundAxis: aroundAxis.position, withDirection: aroundAxis.direction) {
            let ref = OCCTReference(cString: sum)
            return ref
        } else {
            throw OCCTError.couldNotCreateGeometry
        }
    }
    
    func loft(profiles: [OCCTReference]) throws -> OCCTReference {
        if let sum = occt.loft(profiles as [Any], length: Int32(profiles.count)) {
            let ref = OCCTReference(cString: sum)
            return ref
        } else {
            throw OCCTError.couldNotCreateGeometry
        }
    }
    
    func transform(handle: OCCTReference, transformation: SCNMatrix4) {
        occt.setTransformOf(handle, transformation: transformation)
    }
    
    func setPivotOf(handle: OCCTReference, pivot: SCNMatrix4) {
        occt.setPivotOf(handle, pivot: pivot)
    }
    
    /// Calculates a new pivot point for shape based on the center of its bounding box, moves it there, and returns the coordinates.
    func center(handle: OCCTReference) -> SCNVector3 {
        return occt.center(handle);
    }
    
    /// Returns the input points, projected onto a distance-minimizing common plane.
    func flattened(_ of: [SCNVector3]) -> [SCNVector3] {
        var array = [SCNVector3]()
        let res = occt.flattened(of, ofLength: Int32(of.count))
        for i in 0..<of.count {
            array.append(res![i])
        }
        return array
    }
    
    /// Returns the normal vector of the plane fitted through the points (or in other words, the first principal component).
    func pc1(_ of: [SCNVector3]) -> SCNVector3 {
        return occt.pc1(of: of, ofLength: Int32(of.count))
    }
    
    /// Calculates a least-squares fitting circle for the points and returns its center.
    func circleCenter(_ of: [SCNVector3]) -> SCNVector3 {
        return occt.circleCenter(of: of, ofLength: Int32(of.count))
    }
    
    /// Returns 0 of the points are at the same location, 1 if they are on the same line, 2 if they are on the same plane, 3 otherwise, given a certain tolerance.
    func conincidentDimensions(_ of: [SCNVector3]) -> Int {
        return Int(occt.coincidentDimensions(of: of, ofLength: Int32(of.count)))
    }    
    
    /// Returns a triangulated version of the shape as an `SCNGeometry` object.
    func triangulate(handle: OCCTReference) -> SCNGeometry {
        return occt.sceneKitMesh(of: handle)
    }
    
    /// Returns the lines of the shape as an `SCNGeometry` object.
    func wireframe(handle: OCCTReference) -> SCNGeometry {
        return occt.sceneKitLines(of: handle)
    }
    
    /// Returns the lines of the shape as an `SCNGeometry` object in the shape of cylindrical segments.
    func tubeframe(handle: OCCTReference) -> SCNGeometry {
        return occt.sceneKitTubes(of: handle)
    }
    
    /// Exports a shape to stl under the given `filePath`.
    func exportStl(handle: OCCTReference, filePath: URL) {
        var fileName = filePath.absoluteString

        // C function 'fopen' used by OCCT does not work if path starts with "file:///private"
        if fileName.starts(with: "file:///") {
            fileName.removeFirst(8)
        }
        if fileName.starts(with: "private") {
            fileName.removeFirst(7)
        }
        
        occt.stl(of: handle, toFile: fileName.cString(using: String.Encoding.utf8))
    }
    
    /// Effectively deletes a shape's representation.
    func free(handle: OCCTReference) {
        occt.freeShape(handle)
    }
}
