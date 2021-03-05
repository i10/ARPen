//
//  Builders.h
//  ARPen
//
//  Created by Jan Benscheid on 27.09.19.
//  Copyright © 2019 RWTH Aachen. All rights reserved.
//

#ifndef Builders_h
#define Builders_h

#include <SceneKit/SceneKit.h>

@interface Builders : NSObject

+ (const char *) createSphere:(double) radius;
+ (const char *) createBox:(double) width
                    height:(double) height
                    length:(double) length;
+ (const char *) createPyramid:(double) width
                        height:(double) height
                        length:(double) length;
+ (const char *) createCylinder:(double) radius
                         height:(double) height;







+ (const char *) createPath:(const SCNVector3 []) points
                     length:(int) length
                    corners:(const int []) corners
                     closed:(bool) closed;


+ (const char *) updatePath:(const char *)label
                     points: (const SCNVector3 []) points
                     length:(int) length
                     corners:(const int []) corners
                     closed:(bool) closed;











+ (const char *) sweep:(NSString *) profile
                 along:(NSString *) path;




+ (const char *) revolve:(const char *) profile
              aroundAxis:(SCNVector3) axisPosition
           withDirection:(SCNVector3) axisDirection;
+ (const char *) loft:(NSArray *) profiles
               length:(int) length;


+ (const char *) booleanCut:(const char *) a
                   subtract:(const char *) b;
+ (const char *) booleanJoin:(const char *) a
                        with:(const char *) b;
+ (const char *) booleanIntersect:(const char *) a
                             with:(const char *) b;

@end

#endif /* Builders_h */
