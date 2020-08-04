//
//  Insulin4KittiesViewController.m
//  Insulin4Kitties
//
//  Created by Kyle Crockett on 12/31/12.
//  Copyright (c) 2012 Kyle Crockett. All rights reserved.
//

//-- 37.33mm for 30 units
//--37.33mm / 30 = 1.244333 mm per unit
//--8.37mm is 0 displacement
// U-100 syringe is 100 units per 1mL or cc

#import "Insulin4KittiesViewController.h"
#import "MyCvVideoCamera.h"


#define detectMinSize 80
#define unitsPerMM 1.244333
#define syringeBodyLength 61.6
#define plungerZeroDisplacementInMM 8.27
#define unitScalarOffset 1
#define unitAdditiveOffset -1
#define SAMPLE_SIZE 5


NSString * const TFCascadeFilename = @"haarcascade_TF_4_2";//Strings of haar file names
NSString * const FFCascadeFilename = @"haarcascade_FF_3";
NSString * const TIPCascadeFilename = @"haarcascade_TIP_LOW_ERR";

@interface Insulin4KittiesViewController ()


@end

@implementation Insulin4KittiesViewController
@synthesize videoCamera;

//////////////////////////////viewDidLoad///////////////////////////////////////////////////////////////////////////

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    takingMeasurementReading = 0;
    measurementSample = [[NSMutableArray alloc] init];
    
    //Create string of haar file path    
    NSString *TF_cascade_name = [[NSBundle mainBundle] pathForResource:TFCascadeFilename ofType:@"xml"];
    NSString *FF_cascade_name = [[NSBundle mainBundle] pathForResource:FFCascadeFilename ofType:@"xml"];
    NSString *TIP_cascade_name = [[NSBundle mainBundle] pathForResource:TIPCascadeFilename ofType:@"xml"];
    
    //Load haar files, return error message if fail
    if (!TF_cascade.load( [TF_cascade_name UTF8String] )) {
        NSLog(@"Could not load TF cascade!");
    }
    
    if (!FF_cascade.load( [FF_cascade_name UTF8String])) {
        NSLog(@"Could not load FF cascade!");
    }
    
    if (!TIP_cascade.load( [TIP_cascade_name UTF8String])) {
        NSLog(@"Could not load TIP cascade!");
    }
    
    [self.captureProgress setProgress:0.0 animated:YES];
    
    //attach video camera output to imageViewer
    self.videoCamera = [[MyCvVideoCamera alloc] initWithParentView:_imageViewer];
    self.videoCamera.delegate = self;
    
    
    //Configure camera
    self.videoCamera.defaultAVCaptureDevicePosition = AVCaptureDevicePositionBack;
    self.videoCamera.defaultAVCaptureSessionPreset = AVCaptureSessionPresetiFrame1280x720;
    self.videoCamera.defaultFPS = 10;
    self.videoCamera.grayscaleMode = NO;
//    self.videoCamera.
    [self.videoCamera start];
    
    self.videoCamera.defaultAVCaptureVideoOrientation = AVCaptureVideoOrientationLandscapeRight;
    
    //make syringe image invisable and button at full opacity
    _alignmentImage.alpha = 0.0;
    _captureButton.alpha = 1.0;
    
    
}

//////////////////////////////didRecieveMemoryWarning///////////////////////////////////////////////////////////////

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//////////////////////////////StartCapture///////////////////////////////////////////////////////////////////////////

- (IBAction)StartCapture:(id)sender
{
    //toggle video camera bassed on button press
    if (!takingMeasurementReading)
    {
        takingMeasurementReading = 1;
        _alignmentImage.alpha = 0.3;
        _captureButton.alpha = 0.5;
        [measurementSample removeAllObjects];
        //[self.videoCamera start];
    }
    
    
    else if (takingMeasurementReading)
    {
        takingMeasurementReading = 0;
        _alignmentImage.alpha = 0.0;
        _captureButton.alpha = 1.0;
        self.measurementText.text = @"-.-- Units";
        [measurementSample removeAllObjects];
        [self.captureProgress setProgress:0.0];
        //[self.videoCamera stop];
    }
    
}

//////////////////////////////processImage////////////////////////////////////////////////////////////////////////////

- (void)processImage:(Mat&)image
{
    oldTimeInMiliseconds = timeInMiliseconds;
    
    //Location fo detection box in FOV
    offset_x = 280;
    offset_y = 370;
    
    // Dimensions of detection box
    box_height = 140;
    box_width = 700;
    
    if (takingMeasurementReading)
    {
        cv::Rect myROI(offset_x, offset_y, box_width, box_height);
        cv::Mat croppedImage = image(myROI);
        [self detectAndDisplay:image detectionROI:croppedImage];
        
    }
    
    if ([measurementSample count] > SAMPLE_SIZE)
    {
        double valueToBeDisplayed = [self statisticalMean:*measurementSample];
        
        NSString *measurement = [NSString stringWithFormat:@"%.3g Units", (double)valueToBeDisplayed];
        [self.measurementText performSelectorOnMainThread : @ selector(setText:) withObject:measurement waitUntilDone:YES];//display measurement
        NSLog(@"%@",[NSString stringWithFormat:@"Value to be displayed: %.3g",(double)valueToBeDisplayed]);
        
        takingMeasurementReading = 0;
        _alignmentImage.alpha = 0.0;
        _captureButton.alpha = 1.0;
        [self.captureProgress setProgress:1.0];
        
    }

    //timeInMiliseconds = [[NSDate date] timeIntervalSince1970];
    
    //NSLog(@"%@",[NSString stringWithFormat:@"FPS: %.3g", (1/(timeInMiliseconds - oldTimeInMiliseconds))]);
    //NSLog(@"%@",[NSString stringWithFormat:@"%.3g μL", (( )]);
    
    //NSString *measurement = [NSString stringWithFormat:@"%.3g μL", (valueToBeDisplayed)];
    //[self.measurementText performSelectorOnMainThread : @ selector(setText : ) withObject:measurement waitUntilDone:YES];//display measurement
    NSLog(@"%@",[NSString stringWithFormat:@"Length of String: %.2lu",(unsigned long)[measurementSample count]]);
    
    //_captureProgress.progress = [measurementSample count];
    //[self.captureProgress setProgress:(float)[measurementSample count] / (float)SAMPLE_SIZE];
    NSNumber *progress = [NSNumber numberWithFloat:((float)[measurementSample count] / (float)SAMPLE_SIZE)];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.captureProgress setProgress:[progress floatValue] animated: YES];
    });
    
    NSLog(@"%@",[NSString stringWithFormat:@"Progress to be displayed: %f",[self.captureProgress progress]]);
    
}

//////////////////////////////detectAndDisplay/////////////////////////////////////////////////////////////////////////

- (void)detectAndDisplay:(Mat&) frame
             detectionROI:(Mat&) ROI_frame
{
    std::vector<cv::Rect> FFs;
    std::vector<cv::Rect> TFs;
    std::vector<cv::Rect> TIPs;
    
    cv::Mat frame_gray;
    
    cvtColor( ROI_frame, frame_gray, CV_BGR2GRAY );//convert to grayscale
    equalizeHist( frame_gray, frame_gray );
    
    //-- Make Detection Box
    rectangle(frame, cvPoint(offset_x,offset_y), cvPoint(offset_x + box_width,offset_y + box_height), cvScalar(255,255,0),1, 1);
    
    
    //-- Detect syringe
    
    
    TF_cascade.detectMultiScale( frame_gray, TFs, 1.1, 2, 0|CV_HAAR_SCALE_IMAGE, cv::Size(detectMinSize, detectMinSize) );
    
    for( int i = 0; i < TFs.size(); i++ )
    {
        cv::Point center( (TFs[i].x + TFs[i].width*0.5) + offset_x, (TFs[i].y + TFs[i].height*0.5) + offset_y );
        ellipse( frame, center, cv::Size( TFs[i].width*0.5, TFs[i].height*0.5), 0, 0, 360, Scalar( 255, 0, 0 ), 4, 8, 0 );
                
        Mat faceROI = frame_gray( TFs[i] );
        std::vector<cv::Rect> thumbFlange;
    }
    
    
    FF_cascade.detectMultiScale( frame_gray, FFs, 1.1, 2, 0|CV_HAAR_SCALE_IMAGE, cv::Size(detectMinSize, detectMinSize) );
    
    for( int i = 0; i < FFs.size(); i++ )
    {
        cv::Point center( (FFs[i].x + FFs[i].width*0.5) + offset_x, (FFs[i].y + FFs[i].height*0.5) + offset_y );
        cv::ellipse( frame, center, cv::Size( FFs[i].width*0.5, FFs[i].height*0.5), 0, 0, 360, Scalar( 0, 0, 255 ), 4, 8, 0 );
        
        Mat faceROI = frame_gray( FFs[i] );
        std::vector<cv::Rect> fingerFlange;
    }
    
    TIP_cascade.detectMultiScale( frame_gray, TIPs, 1.1, 2, 0|CV_HAAR_SCALE_IMAGE, cv::Size(detectMinSize, detectMinSize) );
    
    for( int i = 0; i < TIPs.size(); i++ )
    {
        cv::Point center( (TIPs[i].x + TIPs[i].width*0.5) + offset_x, (TIPs[i].y + TIPs[i].height*0.5) + offset_y );
        cv::ellipse( frame, center, cv::Size( TIPs[i].width*0.5, TIPs[i].height*0.5), 0, 0, 360, Scalar( 0, 255, 0 ), 4, 8, 0 );
        
        Mat faceROI = frame_gray( TIPs[i] );
        std::vector<cv::Rect> tip;
    }
    
    //Calculate distances between detected objects if all three features detected
    
    if( !FFs.empty() && !TFs.empty() && !TIPs.empty())
    {
        line(frame,
             cvPoint((TFs[0].x + TFs[0].width*0.5) + offset_x, (TFs[0].y+ TFs[0].height*0.5) + offset_y),
             cvPoint((FFs[0].x + FFs[0].width*0.5) + offset_x, (FFs[0].y+ FFs[0].height*0.5) + offset_y),
             cvScalar(255,0,255), 2 );
        TFtoFF = sqrt(pow(((FFs[0].x + FFs[0].width*0.5) - (TFs[0].x + TFs[0].width*0.5)),2)
                          + pow(((FFs[0].y+ FFs[0].height*0.5) - (TFs[0].y+ TFs[0].height*0.5)),2));
        
        line(frame,
             cvPoint((TIPs[0].x + TIPs[0].width*0.5) + offset_x, (TIPs[0].y+ TIPs[0].height*0.5) + offset_y),
             cvPoint((FFs[0].x + FFs[0].width*0.5) + offset_x, (FFs[0].y+ FFs[0].height*0.5) + offset_y),
             cvScalar(0,255,255), 2 );
        FFtoTIP = sqrt(pow(((FFs[0].x + FFs[0].width*0.5) - (TIPs[0].x + TIPs[0].width*0.5)),2)
                       + pow(((FFs[0].y+ FFs[0].height*0.5) - (TIPs[0].y+ TIPs[0].height*0.5)),2));

    
        displacementInMM = ((syringeBodyLength / (double)FFtoTIP) * (double)TFtoFF) - plungerZeroDisplacementInMM;
        syringeVolumeInMicroLitres = ((displacementInMM / unitsPerMM) * unitScalarOffset) + unitAdditiveOffset;
    
    
        // Add readings to array to find average
        NSNumber*num = [NSNumber numberWithDouble:syringeVolumeInMicroLitres];
        [measurementSample addObject:num];
        
    }
}

//////////////////////////////statisticalMean//////////////////////////////////////////////////////////////////////////
                              
-(double)statisticalMean:(NSArray&)dataIn
{
    double mean = 0;
    double sum = 0;
    
    for (NSUInteger i = 0 ; i < [measurementSample count]; i++)
    {
        NSNumber *tempNum = [measurementSample objectAtIndex:i];
        sum += [tempNum doubleValue];
    }
    
    mean = sum/ SAMPLE_SIZE;
    
    return mean;
}

//////////////////////////////StandardDeviation////////////////////////////////////////////////////////////////////////

-(double)standardDeviation:(NSArray&)dataIn;
{
    double stdDev = 0;
    
    for (NSUInteger i = 0; i < [measurementSample count]; i++)
    {
        //do something
    }
    
    return stdDev;
}
@end
