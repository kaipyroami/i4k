//
//  MyCvVideoCamera.m
//  Insulin4Kitties
//
//  Created by Kyle Crockett on 3/8/13.
//  Copyright (c) 2013 Kyle Crockett. All rights reserved.
//

#import "MyCvVideoCamera.h"

#define DEGREES_RADIANS(angle) ((angle) / 180.0 * M_PI)

@implementation MyCvVideoCamera

- (void)updateOrientation;
{
    NSLog(@"Would be rotating now... but I stopped it! :)");
    self.customPreviewLayer.bounds = CGRectMake(0, 0, self.parentView.frame.size.width, self.parentView.frame.size.height);
    [self layoutPreviewLayer];
}



- (void)layoutPreviewLayer;
{
    if (self.parentView != nil)
    {
        CALayer* layer = self.customPreviewLayer;
        CGRect bounds = self.customPreviewLayer.bounds;
        int rotation_angle = 0;
        
        switch (defaultAVCaptureVideoOrientation) {
            case AVCaptureVideoOrientationLandscapeRight:
                rotation_angle = 180;
                break;
            case AVCaptureVideoOrientationPortraitUpsideDown:
                rotation_angle = 270;
                break;
            case AVCaptureVideoOrientationPortrait:
                rotation_angle = 90;
            case AVCaptureVideoOrientationLandscapeLeft:
                break;
            default:
                break;
        }
        
        layer.position = CGPointMake(self.parentView.frame.size.width/2., self.parentView.frame.size.height/2.);
        layer.affineTransform = CGAffineTransformMakeRotation( DEGREES_RADIANS(rotation_angle) );
        layer.bounds = bounds;
    }
}
@end
