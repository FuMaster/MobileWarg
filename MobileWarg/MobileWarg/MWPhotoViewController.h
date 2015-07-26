//
//  MWPhotoViewController.h
//  MobileWarg
//
//  Created by Juhwan Jeong on 2015. 7. 26..
//  Copyright (c) 2015년 MobileWarg. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <FBSDKShareKit/FBSDKShareKit.h>

@interface MWPhotoViewController : UIViewController <UIImagePickerControllerDelegate, UINavigationControllerDelegate, FBSDKSharingDelegate>

@property (nonatomic, strong) UIImage *image;

@end
