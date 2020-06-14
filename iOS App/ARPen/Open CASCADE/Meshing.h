//
//  Meshing.h
//  ARPen
//
//  Created by Jan Benscheid on 27.09.19.
//  Copyright © 2019 RWTH Aachen. All rights reserved.
//

#ifndef Meshing_h
#define Meshing_h

#include <SceneKit/SceneKit.h>

@interface Meshing : NSObject

/// Returns a TopoDS_Shape (referenced by `label`), converted into an `SCNGeometry` object.
+ (SCNGeometry *) sceneKitMeshOf:(const char *) label;
/// Returns all lines of a TopoDS_Shape (referenced by `label`), converted into an `SCNGeometry` object of primitive type "Lines".
+ (SCNGeometry *) sceneKitLinesOf:(const char *) label;
/// Returns all lines of a TopoDS_Shape (referenced by `label`), converted into a  `SCNGeometry` object consisting of a series of cylinders.
+ (SCNGeometry *) sceneKitTubesOf:(const char *) label;
/// Triangulates a TopoDS_Shape (referenced by `label`) and saves it as an stl at `filename`.
+ (void) stlOf:(const char *) label
        toFile:(const char *) filename;

@end

#endif /* Meshing_h */
