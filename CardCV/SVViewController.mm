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

#ifdef __cplusplus
using namespace cv;

vector<cv::Point> GetCardQuadFromImage(Mat src)
{
    Mat src_gray;
    int thresh = 50;
    RNG rng(12345);
    
    // Convert image to gray and blur it
    cvtColor( src, src_gray, CV_BGR2GRAY );
    blur( src_gray, src_gray, cv::Size(3,3) );
    
    Mat canny_output;
    vector<vector<cv::Point> > contours;
    vector<cv::Point> approx;
    vector<Vec4i> hierarchy;
    
    /// Detect edges using canny
    Canny( src_gray, canny_output, thresh, thresh*2, 3 );
    
    /// Find contours
    findContours( canny_output, contours, hierarchy, CV_RETR_TREE, CV_CHAIN_APPROX_SIMPLE, cv::Point(0, 0) );
    
    /// Draw contours
    for( int i = 0; i< contours.size(); i++ )
    {
        Scalar color = Scalar( rng.uniform(0, 255), rng.uniform(0,255), rng.uniform(0,255) );
        approxPolyDP(Mat(contours[i]), approx, arcLength(Mat(contours[i]), true)*0.02, true);
        if( approx.size() == 4 && fabs(contourArea(Mat(approx))) > 10000 && isContourConvex(Mat(approx))) {
            drawContours( src, contours, i, color, 2, 8, hierarchy, 0, cv::Point() );
            return approx;
        }
    }
    
    return approx;
}

cv::Rect pointsToRect(vector<cv::Point> points) {
    int minX = INT_MAX;
    int maxX = INT_MIN;
    int minY = INT_MAX;
    int maxY = INT_MIN;
    for (int i = 0; i < points.size(); i++) {
        minX = MIN(points[i].x, minX);
        maxX = MAX(points[i].x, maxX);
        minY = MIN(points[i].y, minY);
        maxY = MAX(points[i].y, maxY);
    }
    return cv::Rect(minX, minY, maxX - minX, maxY - minY);
}
#endif

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

- (void)processImage:(Mat&)imageMat;
{
    vector<cv::Point> cardPoints = GetCardQuadFromImage(imageMat);
    if (cardPoints.size() == 4 && cardView.image == nil) {
        cv::Rect rect = pointsToRect(cardPoints);
        Mat cardRaw = imageMat(rect);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            cardView.image = [UIImage imageWithCVMat:cardRaw];
        });
    }
}
#endif

@end
