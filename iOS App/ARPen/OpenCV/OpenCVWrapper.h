//
//  OpenCVWrapper.h
//  OpenCV
//
//  Created by Felix Wehnert on 28.09.17.
//  Copyright © 2017 Felix Wehnert. All rights reserved.
//



#import <Foundation/Foundation.h>
#import <CoreVideo/CoreVideo.h>
#import <SceneKit/SceneKit.h>

@protocol OpenCVWrapperDelegate
-(void)markerTranslation:(NSArray<NSValue*>*)translation rotation:(NSArray<NSValue*>*)rotation ids:(NSArray<NSNumber*>*)ids;
-(void)noMarkerFound;
@end

@interface OpenCVWrapper : NSObject

@property id<OpenCVWrapperDelegate> delegate;
-(void)findMarker:(CVPixelBufferRef)pixelBuffer;
@end
