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
#import "Tesseract.h"

@interface SVViewController () <CvVideoCameraDelegate>
{
    IBOutlet UIImageView* imageView;
    IBOutlet UIImageView* cardView;
    IBOutlet UIButton* button;
    IBOutlet UITextView* outputText;
    
    CvVideoCamera* videoCamera;
    BOOL isCameraRunning;
    
    int hasLines[4];
}

- (void)performOCR:(UIImage *)image;

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
    
    outputText.hidden = YES;
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
    outputText.hidden = YES;
    for (int i = 0; i < 4; i++) hasLines[i] = 0;
}

#pragma mark - Protocol CvVideoCameraDelegate

#ifdef __cplusplus
using namespace cv;

BOOL isAngleInRange(float angle, float min, float max) {
    if (min < 0) {
        min += 360;
        max += 360;
        angle += 360;
    }
    return (angle >= min && angle <= max);
}

BOOL isAngleNear(float angle, float target) {
    return isAngleInRange(angle, target - 15, target + 15);
}

BOOL isPositionNear(int pos, int target) {
    return (pos >= target - 10 && pos <= target + 10);
}

BOOL isLineNearX(Vec4i line, int target) {
    float x = (line[0] + line[2])/2;
    return isPositionNear(x, target);
}

BOOL isLineNearY(Vec4i line, int target) {
    float y = (line[1] + line[3])/2;
    return isPositionNear(y, target);
}

- (void)processImage:(Mat&)image;
{
    double start = CFAbsoluteTimeGetCurrent();
    
    Mat dst, cdst;
    Canny(image, dst, 50, 100, 3);
    cvtColor(dst, cdst, CV_GRAY2BGR);
    
    vector<Vec4i> lines;
//  HoughLinesP(dst, lines, rho, theta, threshold, minLineLength=0, maxLineGap=0
    HoughLinesP(dst, lines, 1, CV_PI/180, 50, 50, 10 );
    
    int left = 8;
    int right = 280;
    int top = 80;
    int bottom = 240;
    
    line( cdst, cv::Point(left,  top),    cv::Point(right, top),    Scalar(0,255,0), 1, CV_AA);
    line( cdst, cv::Point(left,  bottom), cv::Point(right, bottom), Scalar(0,255,0), 1, CV_AA);
    line( cdst, cv::Point(left,  top),    cv::Point(left,  bottom), Scalar(0,255,0), 1, CV_AA);
    line( cdst, cv::Point(right, top),    cv::Point(right, bottom), Scalar(0,255,0), 1, CV_AA);
    
    BOOL canSeeLine[4];
    
    for( size_t i = 0; i < lines.size(); i++ )
    {
        Vec4i l = lines[i];
        float angle = cvFastArctan(l[3] - l[1], l[2] - l[0]);
        if (isAngleNear(angle, 0) || isAngleNear(angle, 180)) {
            if (isLineNearY(l, top)) {
                line( cdst, cv::Point(l[0], l[1]), cv::Point(l[2], l[3]), Scalar(0,0,255), 1, CV_AA);
                canSeeLine[0] = YES;
            } else if (isLineNearY(l, bottom)) {
                line( cdst, cv::Point(l[0], l[1]), cv::Point(l[2], l[3]), Scalar(0,0,255), 1, CV_AA);
                canSeeLine[1] = YES;
            }
        }
        if (isAngleNear(angle, 90) || isAngleNear(angle, 270)) {
            if (isLineNearX(l, left)) {
                line( cdst, cv::Point(l[0], l[1]), cv::Point(l[2], l[3]), Scalar(255,0,0), 1, CV_AA);
                canSeeLine[2] = YES;
            } else if (isLineNearX(l, right)) {
                line( cdst, cv::Point(l[0], l[1]), cv::Point(l[2], l[3]), Scalar(255,0,0), 1, CV_AA);
                canSeeLine[3] = YES;
            }
        }
    }
    
    for (int i = 0; i < 4; i++) {
        if (canSeeLine[i]) hasLines[i] = MIN(20, hasLines[i] + 1);
        else hasLines[i] = MAX(0, hasLines[i] - 2);
    }
    
    if (hasLines[0] > 14) line( cdst, cv::Point(left,  top),    cv::Point(right, top),    Scalar(0,255,0), 3, CV_AA);
    if (hasLines[1] > 14) line( cdst, cv::Point(left,  bottom), cv::Point(right, bottom), Scalar(0,255,0), 3, CV_AA);
    if (hasLines[2] > 14) line( cdst, cv::Point(left,  top),    cv::Point(left,  bottom), Scalar(0,255,0), 3, CV_AA);
    if (hasLines[3] > 14) line( cdst, cv::Point(right, top),    cv::Point(right, bottom), Scalar(0,255,0), 3, CV_AA);
    
    BOOL isLookingAtCard = YES;
    for (int i = 0; i < 4; i++) isLookingAtCard = isLookingAtCard && (hasLines[0] > 14);
    
    if (isLookingAtCard && cardView.image == nil) {
        cv::Mat cardRaw;
        cdst(cv::Rect(left, top, right - left, bottom - top)).copyTo(cardRaw);
        UIImage *cardImage = [UIImage imageWithCVMat:cardRaw];
        dispatch_async(dispatch_get_main_queue(), ^{
            cardView.image = cardImage;
            [self performOCR:cardImage];
        });
    }
    
    image = cdst;
    
    double duration = CFAbsoluteTimeGetCurrent() - start;
//    NSLog(@"%f (%.0f) fps", duration, 1.0 / duration);
}

#endif

- (void)performOCR:(UIImage *)image
{
    Tesseract *tesseract = [[Tesseract alloc] initWithDataPath:@"tessdata" language:@"eng"];
    [tesseract setVariableValue:@"0123456789" forKey:@"tessedit_char_whitelist"];
    [tesseract setImage:image];
    [tesseract recognize];
    
    NSString *result = [tesseract recognizedText];
    outputText.text = result;
    outputText.hidden = NO;
    NSLog(@"%@", result);
}

@end
