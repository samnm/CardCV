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

- (void)processImage:(cv::Mat&)imageMat;
{
    
}

#endif

@end
