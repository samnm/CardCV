//
//  SVViewController.m
//  CardCV
//
//  Created by Sam Morrison on 2/1/13.
//  Copyright (c) 2013 Sam Morrison. All rights reserved.
//

#import "SVViewController.h"
#import <opencv2/highgui/cap_ios.h>

#ifdef __cplusplus
using namespace cv;

void DetectAndDrawQuads(Mat src)
{
    Mat src_gray;
    int thresh = 100;
    RNG rng(12345);
    
    // Convert image to gray and blur it
    cvtColor( src, src_gray, CV_BGR2GRAY );
    blur( src_gray, src_gray, cv::Size(3,3) );
    
    Mat canny_output;
    vector<vector<cv::Point> > contours;
    vector<Vec4i> hierarchy;
    
    /// Detect edges using canny
    Canny( src_gray, canny_output, thresh, thresh*2, 3 );
    
    /// Find contours
    findContours( canny_output, contours, hierarchy, CV_RETR_TREE, CV_CHAIN_APPROX_SIMPLE, cv::Point(0, 0) );
    
    /// Draw contours
//    Mat drawing = Mat::zeros( canny_output.size(), CV_8UC3 );
    for( int i = 0; i< contours.size(); i++ )
    {
        Scalar color = Scalar( rng.uniform(0, 255), rng.uniform(0,255), rng.uniform(0,255) );
//        drawContours( drawing, contours, i, color, 2, 8, hierarchy, 0, cv::Point() );
        drawContours( src, contours, i, color, 2, 8, hierarchy, 0, cv::Point() );
    }
    
    contours.clear();
}
#endif

@interface SVViewController () <CvVideoCameraDelegate>
{
    IBOutlet UIImageView* imageView;
    IBOutlet UIButton* button;
    CvVideoCamera* videoCamera;
    BOOL isCameraRunning;
}

@end

@implementation SVViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    videoCamera = [[CvVideoCamera alloc] initWithParentView:imageView];
    videoCamera.delegate = self;
    videoCamera.defaultAVCaptureDevicePosition = AVCaptureDevicePositionBack;
    videoCamera.defaultAVCaptureSessionPreset = AVCaptureSessionPreset352x288;
    videoCamera.defaultAVCaptureVideoOrientation = AVCaptureVideoOrientationPortrait;
    videoCamera.defaultFPS = 5;
    videoCamera.grayscaleMode = NO;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)actionStart:(id)sender
{
    isCameraRunning = !isCameraRunning;
    
    if (isCameraRunning)
        [videoCamera start];
    else
        [videoCamera stop];
}

#pragma mark - Protocol CvVideoCameraDelegate

#ifdef __cplusplus
- (void)processImage:(Mat&)image;
{
    Mat image_copy;
    cvtColor(image, image_copy, CV_BGRA2BGR);
    
    DetectAndDrawQuads(image);
}
#endif

@end
