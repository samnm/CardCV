//
//  SVViewController.m
//  CardCV
//
//  Created by Sam Morrison on 2/1/13.
//  Copyright (c) 2013 Sam Morrison. All rights reserved.
//

#import "SVViewController.h"
#import <opencv2/highgui/cap_ios.h>
#import "UIImage+OpenCV.h"

@interface SVViewController () <CvVideoCameraDelegate>
{
    IBOutlet UIImageView* imageView;
    IBOutlet UIImageView* cardView;
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
    
    if (isCameraRunning) {
        [videoCamera start];
        [button setTitle:@"Stop" forState:UIControlStateNormal];
    } else {
        [videoCamera stop];
        [button setTitle:@"Start" forState:UIControlStateNormal];
    }
}

- (void)clearImage:(id)sender
{
    cardView.image = nil;
}

#pragma mark - Protocol CvVideoCameraDelegate

#ifdef __cplusplus
using namespace cv;

- (void)processImage:(Mat&)image;
{
    Mat dst, cdst;
    Canny(image, dst, 50, 200, 3);
    cvtColor(dst, cdst, CV_GRAY2BGR);
    
    vector<Vec4i> lines;
    HoughLinesP(dst, lines, CV_HOUGH_GRADIENT, CV_PI/180, 50, 50, 10 );
    for( size_t i = 0; i < lines.size(); i++ )
    {
        Vec4i l = lines[i];
        line( cdst, cv::Point(l[0], l[1]), cv::Point(l[2], l[3]), Scalar(0,0,255), 1, CV_AA);
    }
    image = cdst;
}

#endif

@end
