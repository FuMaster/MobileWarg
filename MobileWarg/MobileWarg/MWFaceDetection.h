//
//  MWFaceDetection.h
//  MobileWarg
//
//  Created by Juhwan Jeong on 2015. 7. 18..
//  Copyright (c) 2015년 MobileWarg. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

@interface MWFaceDetection : NSObject

+ (MWFaceDetection *)detectionManager;
- (UIImage *) processImage:(UIImage *)image;

@end
