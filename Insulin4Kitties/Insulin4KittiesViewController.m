//
//  Insulin4KittiesViewController.m
//  Insulin4Kitties
//
//  Created by Kyle Crockett on 12/31/12.
//  Copyright (c) 2012 Kyle Crockett. All rights reserved.
//

#import "Insulin4KittiesViewController.h"

#define detectMinSize 80

NSString * const TFCascadeFilename = @"haarcascade_TF";//Strings of haar file names
NSString * const FFCascadeFilename = @"haarcascade_FF_2";

@interface Insulin4KittiesViewController ()


@end

@implementation Insulin4KittiesViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    //Create string of haar file path    
    NSString *TF_cascade_name = [[NSBundle mainBundle] pathForResource:TFCascadeFilename ofType:@"xml"];
    NSString *FF_cascade_name = [[NSBundle mainBundle] pathForResource:FFCascadeFilename ofType:@"xml"];
    
    //Load haar files, return error message if fail
    if (!TF_cascade.load( [TF_cascade_name UTF8String] )) {
        NSLog(@"Could not load TF cascade!");
    }
    
    if (!FF_cascade.load( [FF_cascade_name UTF8String])) {
        NSLog(@"Could not load FF cascade!");
    }
    
    //attach video camera output to imageViewer
    self.videoCamera = [[CvVideoCamera alloc] initWithParentView:_imageViewer];
    self.videoCamera.delegate = self;
    
    //Configure camera
    self.videoCamera.defaultAVCaptureDevicePosition = AVCaptureDevicePositionBack;
    self.videoCamera.defaultAVCaptureSessionPreset = AVCaptureSessionPresetiFrame1280x720;
    self.videoCamera.defaultFPS = 30;
    self.videoCamera.grayscaleMode = NO;
    
    self.videoCamera.defaultAVCaptureVideoOrientation = AVCaptureVideoOrientationLandscapeRight; // Does not seem to be working correctly
    
    //make syringe image invisable and button at full opacity
    _alignmentImage.alpha = 0.0;
    _captureButton.alpha = 1.0;
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)StartCapture:(id)sender
{
    //toggle video camera bassed on button press
    if (!self.videoCamera.running)
    {
        [self.videoCamera start];
        _alignmentImage.alpha = 0.3;
        _captureButton.alpha = 0.5;
        //_captureButton.backgroundColor = [UIColor redColor];
    }
    
    
    else if (self.videoCamera.running)
    {
        [self.videoCamera stop];
        _alignmentImage.alpha = 0.0;
        _captureButton.alpha = 1.0;
        //_captureButton.backgroundColor = nil;
    }
    
}

- (void)processImage:(Mat&)image
{
    oldTimeInMiliseconds = timeInMiliseconds;
    
    //Location fo detection box in FOV
    offset_x = 400;
    offset_y = 150;
    
    // Dimensions of detection box
    box_height = 200;
    box_width = 500;
    
    cv::Rect myROI(offset_x, offset_y, box_width, box_height);
    
    cv::Mat croppedImage = image(myROI);
    [self detectAndDisplay:image detectionROI:croppedImage];

    timeInMiliseconds = [[NSDate date] timeIntervalSince1970];
    
    NSLog(@"%@",[NSString stringWithFormat:@"FPS: %.3g", (1/(timeInMiliseconds - oldTimeInMiliseconds))]);
    
}

/** detectAndDisplay */
- (void)detectAndDisplay:(Mat&) frame
             detectionROI:(Mat&) ROI_frame
{
    std::vector<cv::Rect> FFs;
    std::vector<cv::Rect> TFs;
    
    cv::Mat frame_gray;
    
    cvtColor( ROI_frame, frame_gray, CV_BGR2GRAY );//convert to grayscale
    equalizeHist( frame_gray, frame_gray );
    
    //Make Detection Box
    rectangle(frame, cvPoint(offset_x,offset_y), cvPoint(offset_x + box_width,offset_y + box_height), cvScalar(0,255,0),1, 1);
    
    
    //Detect thumb flange
    TF_cascade.detectMultiScale( frame_gray, TFs, 1.1, 2, 0|CV_HAAR_SCALE_IMAGE, cv::Size(detectMinSize, detectMinSize) );
    
    //Draw circle
    for( int i = 0; i < TFs.size(); i++ )
    {
        cv::Point center( (TFs[i].x + TFs[i].width*0.5) + offset_x, (TFs[i].y + TFs[i].height*0.5) + offset_y );
        ellipse( frame, center, cv::Size( TFs[i].width*0.5, TFs[i].height*0.5), 0, 0, 360, Scalar( 255, 0, 0 ), 4, 8, 0 );
                
        Mat faceROI = frame_gray( TFs[i] );
        std::vector<cv::Rect> eyes;        
    }
    
    //Detect finger flange
    FF_cascade.detectMultiScale( frame_gray, FFs, 1.1, 2, 0|CV_HAAR_SCALE_IMAGE, cv::Size(detectMinSize, detectMinSize) );
    
    //Draw circle
    for( int i = 0; i < FFs.size(); i++ )
    {
        cv::Point center( (FFs[i].x + FFs[i].width*0.5) + offset_x, (FFs[i].y + FFs[i].height*0.5) + offset_y );
        cv::ellipse( frame, center, cv::Size( FFs[i].width*0.5, FFs[i].height*0.5), 0, 0, 360, Scalar( 0, 0, 255 ), 4, 8, 0 );
        
        Mat faceROI = frame_gray( FFs[i] );
        std::vector<cv::Rect> eyes;
    }
    

}



@end
