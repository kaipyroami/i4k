//
//  Insulin4KittiesViewController.h
//  Insulin4Kitties
//
//  Created by Kyle Crockett on 12/31/12.
//  Copyright (c) 2012 Kyle Crockett. All rights reserved.
//


#import <UIKit/UIKit.h>
#import <opencv2/highgui/cap_ios.h>
#include <opencv2/objdetect/objdetect.hpp>
#include <opencv2/highgui/highgui.hpp>
#include <opencv2/imgproc/imgproc.hpp>
#include <opencv2/core/core.hpp>
#include <opencv2/features2d/features2d.hpp>
#include <iostream>
#include <math.h>


using namespace cv;
using namespace std;


@interface Insulin4KittiesViewController : UIViewController <CvVideoCameraDelegate>
{
    CvVideoCamera *_videoCamera;
    
    cv::CascadeClassifier TF_cascade;
    cv::CascadeClassifier FF_cascade;
    int offset_x;
    int offset_y;
    int box_height;
    int box_width;
    NSTimeInterval timeInMiliseconds;
    NSTimeInterval oldTimeInMiliseconds;
    Mat frameIn;
    
}

- (IBAction)StartCapture:(id)sender;
- (void)processImage:(Mat&)image;
- (void)detectAndDisplay:(Mat&) frame
             detectionROI:(Mat&) ROI_frame;


@property (weak, nonatomic) IBOutlet UILabel *measurementText;
@property (weak, nonatomic) IBOutlet UIImageView *imageViewer;
@property (nonatomic, retain) CvVideoCamera *videoCamera;
@property (weak, nonatomic) IBOutlet UIImageView *alignmentImage;
@property (weak, nonatomic) IBOutlet UIButton *captureButton;



@end
