//
//  SVViewController.m
//  CardCV
//
//  Created by Sam Morrison on 2/1/13.
//  Copyright (c) 2013 Sam Morrison. All rights reserved.
//

#import "SVViewController.h"
#import <opencv2/highgui/cap_ios.h>

@interface SVViewController () <CvVideoCameraDelegate>
{
    IBOutlet UIImageView* imageView;
    IBOutlet UIButton* button;
    CvVideoCamera* videoCamera;
}

@end

@implementation SVViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    videoCamera = [[CvVideoCamera alloc] initWithParentView:imageView];
    videoCamera.delegate = self;
    videoCamera.defaultAVCaptureDevicePosition = AVCaptureDevicePositionFront;
    videoCamera.defaultAVCaptureSessionPreset = AVCaptureSessionPreset352x288;
    videoCamera.defaultAVCaptureVideoOrientation = AVCaptureVideoOrientationPortrait;
    videoCamera.defaultFPS = 30;
    videoCamera.grayscaleMode = NO;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)actionStart:(id)sender
{
    
}

#pragma mark - Protocol CvVideoCameraDelegate

#ifdef __cplusplus
- (void)processImage:(Mat&)image;
{
    // Do some OpenCV stuff with the image
}
#endif

@end
