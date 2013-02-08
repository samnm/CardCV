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
    BOOL hasResult;
    
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
    videoCamera.defaultAVCaptureSessionPreset = AVCaptureSessionPreset1280x720;
    videoCamera.defaultAVCaptureVideoOrientation = AVCaptureVideoOrientationPortrait;
    videoCamera.defaultFPS = 15;
    videoCamera.grayscaleMode = NO;
    [videoCamera start];
    
    AVCaptureDevice *device = ((AVCaptureDeviceInput *)[[videoCamera.captureSession inputs] objectAtIndex:0]).device;
    NSError *error;
    if ([device isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus] && device.isFocusPointOfInterestSupported) {
        if ([device lockForConfiguration:&error]) {
            [device setFocusPointOfInterest:CGPointMake(0.75, 0.5)];
            [device setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
            [device unlockForConfiguration];
        } else {
            NSLog(@"Error: %@", error);
        }
    }
    
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
        [button setTitle:@"Stop" forState:UIControlStateNormal];
    } else {
        [button setTitle:@"Start" forState:UIControlStateNormal];
    }
}

- (void)clearImage:(id)sender
{
    hasResult = NO;
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
    if (!isCameraRunning) return;
    
    float processingScale = 0.15;
    
    cv::Size imageSize = image.size();
    Mat src;
    cv::resize(image, src, cv::Size(imageSize.width * processingScale, imageSize.height * processingScale));
    Mat dst, cdst;
    Canny(src, dst, 50, 100, 3);
    cvtColor(dst, cdst, CV_GRAY2BGR);
    
    vector<Vec4i> lines;
    HoughLinesP(dst, lines, 1, CV_PI/180, 50, 50, 10 );
    
    int imageWidth = videoCamera.imageHeight * processingScale;
    
    int boundSize = 3;
    int left = boundSize;
    int right = imageWidth - boundSize;
    int top = imageWidth / 4;
    int bottom = top + (right - left) * 0.63;
    
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
    
    if (isLookingAtCard && !hasResult) {
        hasResult = YES;
        cv::Mat cardOriginal;
        image(cv::Rect(left / processingScale, top / processingScale, (right - left) / processingScale, (bottom - top) / processingScale)).copyTo(cardOriginal);
        UIImage *cardOriginalImage = [UIImage imageWithCVMat:cardOriginal];
        dispatch_async(dispatch_get_main_queue(), ^{
            outputText.text = @"Loading...";
            outputText.hidden = NO;
        });
        [self performOCR:cardOriginalImage];
    }
    
    image = cdst;
}

- (void)performOCR:(UIImage *)image
{
    Mat src = [image CVMat];
    Mat src_gray;
    RNG rng(12345);
    
    // Convert image to gray and blur it
    cvtColor( src, src_gray, CV_BGR2GRAY );
    blur( src_gray, src_gray, cv::Size(2,2) );
    
    Mat canny_output;
    vector<vector<cv::Point> > contours;
    vector<cv::Point> approx;
    vector<Vec4i> hierarchy;
    
    /// Detect edges using canny
    Canny( src_gray, canny_output, 50, 150, 3 );
    
    int morph_size = 2;
    Mat element = getStructuringElement( MORPH_ELLIPSE,
                                        cv::Size( 2*morph_size + 1, 2*morph_size+1 ),
                                        cv::Point( morph_size, morph_size ) );
    /// Apply the dilation operation
    morphologyEx(canny_output, canny_output, MORPH_CLOSE, element);
    blur(canny_output, canny_output, cv::Size(2, 2));
    morphologyEx(canny_output, canny_output, MORPH_CLOSE, element);
    
    UIImage *processedImage = [UIImage imageWithCVMat:canny_output];
    
    Tesseract *tesseract = [[Tesseract alloc] initWithDataPath:@"tessdata" language:@"eng"];
    [tesseract setVariableValue:@"0123456789" forKey:@"tessedit_char_whitelist"];
    [tesseract setImage:processedImage];
    [tesseract recognize];
    
    NSString *result = [tesseract recognizedText];
    dispatch_async(dispatch_get_main_queue(), ^{
        cardView.image = processedImage;
        outputText.text = result;
        outputText.hidden = NO;
    });
}

#endif

@end
