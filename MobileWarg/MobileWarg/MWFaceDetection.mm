//
//  MWFaceDetection.m
//  MobileWarg
//
//  Created by Juhwan Jeong on 2015. 7. 18..
//  Copyright (c) 2015년 MobileWarg. All rights reserved.
//

#import "MWFaceDetection.h"
#import <opencv2/highgui/cap_ios.h>
#import <opencv2/opencv.hpp>


using namespace cv;

// set this to whichever file you want to use.
NSString* const kFaceCascadeName = @"haarcascade_frontalface_alt";

#ifdef __cplusplus
CascadeClassifier face_cascade;
#endif

@implementation MWFaceDetection

+ (MWFaceDetection *)detectionManager {
    static MWFaceDetection *detection = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        detection = [[self alloc] init];
    });
    return detection;
}

- (id) init {
    NSString *faceCascadePath = [[NSBundle mainBundle] pathForResource:kFaceCascadeName
                                                                ofType:@"xml"];
    #ifdef __cplusplus
        if(!face_cascade.load([faceCascadePath UTF8String])) {
            NSLog(@"Could not load face classifier!");
        }
    #endif
    return self;
}

 #ifdef __cplusplus
- (cv::Mat)cvMatFromUIImage:(UIImage *)image
{
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    CGFloat cols = image.size.width;
    CGFloat rows = image.size.height;
    
    cv::Mat cvMat(rows, cols, CV_8UC4); // 8 bits per component, 4 channels (color channels + alpha)
    
    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to  data
                                                    cols,                       // Width of bitmap
                                                    rows,                       // Height of bitmap
                                                    8,                          // Bits per component
                                                    cvMat.step[0],              // Bytes per row
                                                    colorSpace,                 // Colorspace
                                                    kCGImageAlphaNoneSkipLast |
                                                    kCGBitmapByteOrderDefault); // Bitmap info flags
    
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
    CGContextRelease(contextRef);
    
    return cvMat;
}

- (void) processImage:(UIImage *)image {
    Mat temp = [self cvMatFromUIImage:image];
    [self processMatImage:temp];
}

- (void) processMatImage:(Mat &)image
{
    vector<cv::Rect> faces;
    Mat frame_gray;
    
    cvtColor(image, frame_gray, CV_BGRA2GRAY);
    equalizeHist(frame_gray, frame_gray);
    
    face_cascade.detectMultiScale(frame_gray, faces, 1.1, 2, 0 | CV_HAAR_SCALE_IMAGE, cv::Size(100, 100));
    
    for(unsigned int i = 0; i < faces.size(); ++i) {
        rectangle(image, cv::Point(faces[i].x, faces[i].y),
                  cv::Point(faces[i].x + faces[i].width, faces[i].y + faces[i].height),
                  cv::Scalar(0,255,255));
    }
}
#endif


@end
