//
//  MWFacebookManager.h
//  MobileWarg
//
//  Created by Richard Li on 2015-07-12.
//  Copyright (c) 2015 MobileWarg. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <FBSDKShareKit/FBSDKShareKit.h>

@import Social;

@interface MWFacebookManager : NSObject
+ (FBSDKSharePhotoContent*)shareToFacebook:(UIImage *)image;
+ (SLComposeViewController*)openShareDialog:(UIImage *)image;

@end
