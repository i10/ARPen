//
//  OCCT.h
//  ARPen
//
//  Created by Jan Benscheid on 25.01.19.
//  Copyright © 2019 RWTH Aachen. All rights reserved.
//

#ifndef OCCT_h
#define OCCT_h

#include <UIKit/UIKit.h>
#include <SceneKit/SceneKit.h>

/**
 In general: A TopoDS_Shape (OCCTs internal geometry representation) is referenced by a C string (const char *)
 */
@interface OCCT : NSObject

// Methods from Registry
/// Effectively deletes a shape
- (void) freeShape:(const char *) handle;


// Methods from Helpers
/// For transformations which include scaling. Warning: As scaling was not possible for the user, this function has not been tested since early in the development and might contain errors.
- (void) setGTransformOf:(const char *) label
                  affine:(SCNMatrix4) affine
             translation:(SCNVector3) translation;
- (void) setTransformOf:(const char *) label
         transformation:(SCNMatrix4) mat;
- (void) setPivotOf:(const char *) label
              pivot:(SCNMatrix4) mat;

/// Calculates a new pivot point for shape based on the center of its bounding box, moves it there, and returns the coordinates.
-(SCNVector3) center:(const char *) label;

/// Returns the input points, projected onto a distance-minimizing common plane.
- (const SCNVector3 *) flattened:(const SCNVector3 []) points
                        ofLength:(int) length;

/// Calculates a least-squares fitting circle for the points and returns its center.
- (SCNVector3) circleCenterOf:(const SCNVector3 []) points
                     ofLength:(int) length;
/// Returns the normal vector of the plane fitted through the points (or in other words, the first principal component).
- (SCNVector3) pc1Of:(const SCNVector3 []) points
            ofLength:(int) length;
/// Returns 0 of the points are at the same location, 1 if they are on the same line, 2 if they are on the same plane, 3 otherwise, given a certain tolerance.
- (int) coincidentDimensionsOf:(const SCNVector3 [])points
                      ofLength:(int)length;


// Methods from Builders
// I hope the method headers are self-documenting :P
- (const char *) createSphere:(double) radius;
- (const char *) createBox:(double) width
                    height:(double) height
                    length:(double) length;
- (const char *) createPyramid:(double) width
                    height:(double) height
                    length:(double) length;
- (const char *) createCylinder:(double) radius
                         height:(double) height;






- (const char *) createPath:(const SCNVector3 []) points
                     length:(int) length
                    corners:(const int []) corners
                     closed:(bool) closed;


- (const char *) updatePath:(const char *)label
                     points: (const SCNVector3 []) points
                     length:(int) length
                     corners:(const int []) corners
                     closed:(bool) closed;





- (const char *) sweep:(NSString *) profile
                 along:(NSString *) path;



- (const char *) revolve:(const char *) profile
              aroundAxis:(SCNVector3) axisPosition
           withDirection:(SCNVector3) axisDirection;



- (const char *) loft:(NSArray *) profiles
               length:(int) length;

- (const char *) booleanCut:(const char *) a
                   subtract:(const char *) b;
- (const char *) booleanJoin:(const char *) a
                        with:(const char *) b;
- (const char *) booleanIntersect:(const char *) a
                             with:(const char *) b;


// Methods from Meshing
/// Returns a TopoDS_Shape (referenced by `label`), converted into an `SCNGeometry` object.
- (SCNGeometry *) sceneKitMeshOf:(const char *) label;
/// Returns all lines of a TopoDS_Shape (referenced by `label`), converted into an `SCNGeometry` object of primitive type "Lines".
- (SCNGeometry *) sceneKitLinesOf:(const char *) label;
/// Returns all lines of a TopoDS_Shape (referenced by `label`), converted into a  `SCNGeometry` object consisting of a series of cylinders.
- (SCNGeometry *) sceneKitTubesOf:(const char *) label;
/// Triangulates a TopoDS_Shape (referenced by `label`) and saves it as an stl at `filename`.
- (void) stlOf:(const char *) label
        toFile:(const char *) filename;

@end

#endif /* OCCT_h */
