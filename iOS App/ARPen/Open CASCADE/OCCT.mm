//
//  OCCT.m
//  ARPen
//
//  Created by Jan Benscheid on 25.01.19.
//  Copyright © 2019 RWTH Aachen. All rights reserved.
//

#import <Foundation/Foundation.h>

#include "OCCT.h"
#include "Registry.h"
#include "Helpers.h"
#include "Builders.h"
#include "Meshing.h"

/// This class just forwards function calls. I did not find a more elegant way on how to achieve Swift-compatibility on the spot, but probably there is.
@implementation OCCT : NSObject

// Registry
- (void) freeShape:(const char *) handle {
    [Registry freeShape:handle];
}


// Helpers
- (SCNVector3) center:(const char *) label {
    return [Helpers center:label];
}

- (const SCNVector3 *) flattened:(const SCNVector3 []) points
                        ofLength:(int) length {
    return [Helpers flattened:points ofLength:length];
}

- (SCNVector3) pc1Of:(const SCNVector3 []) points
            ofLength:(int) length {
    return [Helpers pc1Of:points ofLength:length];
}

- (SCNVector3) circleCenterOf:(const SCNVector3 []) points
                     ofLength:(int) length {
    return [Helpers circleCenterOf:points ofLength:length];
}

- (int) coincidentDimensionsOf:(const SCNVector3 []) points
                      ofLength:(int) length {
    return [Helpers coincidentDimensionsOf:points ofLength:length];
}

- (void) setGTransformOf:(const char *) label
                  affine:(SCNMatrix4) affine
             translation:(SCNVector3) translation {
    return [Helpers setGTransformOf:label affine:affine translation:translation];
}

- (void) setTransformOf:(const char *) label
         transformation:(SCNMatrix4) mat {
    return [Helpers setTransformOf:label transformation:mat];
}

- (void) setPivotOf:(const char *) label
              pivot:(SCNMatrix4) mat {
    return [Helpers setPivotOf:label pivot:mat];
}



// Builders
- (const char *) createSphere:(double) radius {
    return [Builders createSphere:radius];
}

- (const char *) createBox:(double) width
                    height:(double) height
                    length:(double) length {
    return [Builders createBox:width height:height length:length];
}

- (const char *) createPyramid:(double) width
                    height:(double) height
                    length:(double) length {
    return [Builders createPyramid:width height:height length:length];
}

- (const char *) createCylinder:(double) radius
                         height:(double) height {
    return [Builders createCylinder:radius height:height];
}









- (const char *) createPath:(const SCNVector3 []) points
                     length:(int) length
                    corners:(const int []) corners
                     closed:(bool) closed {
    return [Builders createPath:points length:length corners:corners closed:closed];
}


- (const char *) updatePath:(const char *)label
                     points: (const SCNVector3 []) points
                     length:(int) length
                     corners:(const int []) corners
                     closed:(bool) closed{
    return [Builders updatePath:label points:points length:length corners:corners closed:closed ];
}











- (const char *) sweep:(NSString *) profile
                 along:(NSString *) path {
    return [Builders sweep:profile along:path];
}

- (const char *) revolve:(const char *) profile
              aroundAxis:(SCNVector3) axisPosition
           withDirection:(SCNVector3) axisDirection {
    return [Builders revolve:profile aroundAxis:axisPosition withDirection:axisDirection];
}

- (const char *) loft:(NSArray *) profiles
               length:(int) length {
    return [Builders loft:profiles length:length];
}


- (const char *) booleanCut:(const char *) a
                   subtract:(const char *) b {
    return [Builders booleanCut:a subtract:b];
}

- (const char *) booleanJoin:(const char *) a
                        with:(const char *) b {
    return [Builders booleanJoin:a with:b];
}

- (const char *) booleanIntersect:(const char *) a
                             with:(const char *) b {
    return [Builders booleanIntersect:a with:b];
}


// Meshing
- (SCNGeometry *) sceneKitMeshOf:(const char *) label {
    return [Meshing sceneKitMeshOf:label];
}

- (SCNGeometry *) sceneKitLinesOf:(const char *) label {
    return [Meshing sceneKitLinesOf:label];
}

- (SCNGeometry *) sceneKitTubesOf:(const char *) label {
    return [Meshing sceneKitTubesOf:label];
}

- (void) stlOf:(const char *) label
        toFile:(const char *) filename {
    return [Meshing stlOf:label toFile:filename];
}

@end
