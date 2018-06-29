//
//  MarkerBox.h
//  OpenCV
//
//  Created by Felix Wehnert on 23.10.17.
//  Copyright © 2017 Felix Wehnert. All rights reserved.
//

#import <SceneKit/SceneKit.h>

@interface MarkerBox : SCNNode
- (instancetype)init;
- (SCNVector3)positionWithIds:(int*)ids count:(int)count;
- (SCNVector3)rotationWithIds:(int*)ids count:(int)count;
- (void)setPosition:(SCNVector3)position rotation:(SCNVector3)rotation forId:(int)markerId;
- (void)setTransform:(SCNMatrix4)transform forId:(int)markerID;
@end
