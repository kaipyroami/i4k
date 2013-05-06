//
//  MyCvVideoCamera.h
//  Insulin4Kitties
//
//  Created by Kyle Crockett on 3/8/13.
//  Copyright (c) 2013 Kyle Crockett. All rights reserved.
//
//  This overides the automatic rotating of the camera input based on device orientation.

#import <opencv2/highgui/cap_ios.h>

@protocol MyCvVideoCameraDelegate <CvVideoCameraDelegate>
@end

@interface MyCvVideoCamera : CvVideoCamera

- (void)updateOrientation;
- (void)layoutPreviewLayer;

@property (nonatomic, retain) CALayer *customPreviewLayer;

@end