//
//  MWFacebookManager.m
//  MobileWarg
//
//  Created by Richard Li on 2015-07-12.
//  Copyright (c) 2015 MobileWarg. All rights reserved.
//

#import "MWFacebookManager.h"

@implementation MWFacebookManager
+ (FBSDKSharePhotoContent*)shareToFacebook:(UIImage *)image {
    FBSDKSharePhoto *photo = [[FBSDKSharePhoto alloc] init];
    photo.image = image;
    photo.userGenerated = YES;
    
    FBSDKSharePhotoContent *content = [[FBSDKSharePhotoContent alloc] init];
    content.photos = @[photo];
    return content;
}

+ (SLComposeViewController*)openShareDialog:(UIImage *)image {
    if([SLComposeViewController isAvailableForServiceType:SLServiceTypeFacebook]) {
        
        SLComposeViewController *controller = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeFacebook];
        
        [controller setInitialText:@"Posted with MobileWarg app"];
        [controller addURL:[NSURL URLWithString:@"http://www.mobilewarg.com"]];
        [controller addImage: image];
        return controller;
    }
    return nil;
}
@end
