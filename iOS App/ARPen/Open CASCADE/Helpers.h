//
//  Helpers.h
//  ARPen
//
//  Created by Jan Benscheid on 27.09.19.
//  Copyright © 2019 RWTH Aachen. All rights reserved.
//

#ifndef Helpers_h
#define Helpers_h

#include <SceneKit/SceneKit.h>

#include <occt/TColgp_Array1OfPnt.hxx>
#include <occt/gp_Pln.hxx>

@interface Helpers : NSObject

/// For transformations which include scaling. Warning: As scaling was not possible for the user, this function has not been tested since early in the development and might contain errors.
+ (void) setGTransformOf:(const char *) label
                  affine:(SCNMatrix4) affine
             translation:(SCNVector3) translation;
+ (void) setTransformOf:(const char *) label
         transformation:(SCNMatrix4) mat;
+ (void) setPivotOf:(const char *) label
              pivot:(SCNMatrix4) mat;

/// Calculates a new pivot point for shape based on the center of its bounding box, moves it there, and returns the coordinates.
+ (SCNVector3) center:(const char *) label;

/// Returns the input points, projected onto a distance-minimizing common plane.
+ (const SCNVector3 *) flattened:(const SCNVector3 []) points
                        ofLength:(int) length;

/// Calculates a least-squares fitting circle for the points and returns its center.
+ (SCNVector3) circleCenterOf:(const SCNVector3 []) points
                     ofLength:(int) length;
/// Returns the normal vector of the plane fitted through the points (or in other words, the first principal component).
+ (SCNVector3) pc1Of:(const SCNVector3 []) points
            ofLength:(int) length;
/// Returns 0 of the points are at the same location, 1 if they are on the same line, 2 if they are on the same plane, 3 otherwise, given a certain tolerance.
+ (int) coincidentDimensionsOf:(const SCNVector3 [])points
                      ofLength:(int)length;

/// Calculates a distance-minimizing common plane for the input points.
+ (gp_Pln) getFittingPlane:(const TColgp_Array1OfPnt&) ocPoints;
/// Convert points from SCNVector3 to gp_Pnt.
+ (TColgp_Array1OfPnt) convertPoints:(const SCNVector3 []) points
                            ofLength:(int) length;


@end

#endif /* Helpers_h */
