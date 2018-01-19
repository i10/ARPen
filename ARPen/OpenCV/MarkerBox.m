//
//  MarkerBox.m
//  OpenCV
//
//  Created by Felix Wehnert on 23.10.17.
//  Copyright © 2017 Felix Wehnert. All rights reserved.
//

#import "MarkerBox.h"

@interface MarkerBox()

@property NSArray<SCNNode*>* markerArray;

@end

@implementation MarkerBox
@synthesize markerArray;

#define RADIANS_TO_DEGREES(radians) ((radians) * (180.0 / M_PI))
#define DEGREES_TO_RADIANS(angle) ((angle) / 180.0 * M_PI)

/**
 The initializer will calculate the posistion of the pencil point and will initialize all needed properties.
 */
- (instancetype)init
{
    self = [super init];
    if (self) {
        self.name = @"MarkerBox";
        markerArray = [NSArray arrayWithObjects:[SCNNode node], [SCNNode node], [SCNNode node], [SCNNode node], [SCNNode node], [SCNNode node], nil];
        float a = 0.15; // The length of the pencil.
        float xs, ys, zs;
        
        ys = xs = ((cos(DEGREES_TO_RADIANS(35.3))*a)+0.005)/sqrt(2);
        zs = sin(DEGREES_TO_RADIANS(35.3))*a;
        zs -= 0.02;
        xs *= -1;
        ys *= -1;
        zs *= -1;
        
        float xl, yl, zl;
        
        yl = xl = (cos(DEGREES_TO_RADIANS(35.3))*a)/sqrt(2);
        zl = sin(DEGREES_TO_RADIANS(35.3))*a;
        zl += 0.02;
        xl *= -1;
        yl *= -1;
        
        // Place every children at the correct relative position.
        [markerArray enumerateObjectsUsingBlock:^(SCNNode * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            obj.name = [NSString stringWithFormat:@"Marker #%lu", (idx+1)];
            SCNNode* point = [SCNNode node];
            point.name = [NSString stringWithFormat:@"Point from #%lu", (idx+1)];
            
            switch(idx) {
                case 0: // Marker 1 small
                    point.position = SCNVector3Make(xs, ys, zs);
                    break;
                case 1: // Marker 2 small
                    point.position = SCNVector3Make(xs, ys, zs);
                    break;
                case 2: // Marker 3 small
                    point.position = SCNVector3Make(xs, ys, zs);
                    break;
                case 3: // Marker 4 big
                    point.position = SCNVector3Make(-xl, yl, zl);
                    break;
                case 4: // Marker 5 big
                    point.position = SCNVector3Make(xl, yl, zl);
                    break;
                case 5: // Marker 6 big
                    point.position = SCNVector3Make(-xl, yl, zl);
                    break;
            }
            
            [obj addChildNode:point];
            [self addChildNode:obj];
        }];
    }
    return self;
}

/**
 Sets the position for a specific marker
 */
- (void)setPosition:(SCNVector3)position rotation:(SCNVector3)rotation forId:(int)markerId {
    [[self.markerArray objectAtIndex:markerId-1] setPosition:position];
    [[self.markerArray objectAtIndex:markerId-1] setEulerAngles:rotation];
}

/**
 Sets the transform for a specific marker
 */
-(void)setTransform:(SCNMatrix4)transform forId:(int)markerID {
    [[self.markerArray objectAtIndex:markerID-1] setTransform:transform];
}

/**
 Calculates the position of the pencil point based on the given marker ids.
 */
- (SCNVector3)positionWithIds:(int*)ids count:(int)count {
    __block SCNVector3 vector = SCNVector3Zero;

    for(int i = 0; i < count; i++) {
        int markerId = ids[i];
        SCNVector3 point = [[[self.markerArray objectAtIndex:markerId-1].childNodes objectAtIndex:0] convertPosition:SCNVector3Zero toNode:nil];
        vector.x += point.x;
        vector.y += point.y;
        vector.z += point.z;
    }
    
    vector.x /= count;
    vector.y /= count;
    vector.z /= count;
    return vector;
}

/**
 Calculate the rotation of the marker box based on the given marker ids.
 */
- (SCNVector3)rotationWithIds:(int*)ids count:(int)count {
    SCNMatrix4 matrix = [[[self.markerArray objectAtIndex:ids[0]-1].childNodes objectAtIndex:0] convertTransform:SCNMatrix4Identity toNode:nil];
    SCNNode* node = [SCNNode node];
    node.transform = matrix;
    return node.eulerAngles;
}

@end
