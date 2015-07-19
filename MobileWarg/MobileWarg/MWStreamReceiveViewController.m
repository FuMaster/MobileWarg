//
//  MWStreamReceiveViewController.m
//  MobileWarg
//
//  Created by David Jeong on 2015-06-13.
//  Copyright (c) 2015 MobileWarg. All rights reserved.
//

#import "MWStreamReceiveViewController.h"

@interface MWStreamReceiveViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@end

@implementation MWStreamReceiveViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Receiving Feed";
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - MWMultipeerVideoReceiver

- (void)receiveVideoFrame:(NSData *)videoFrame {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.imageView.image = [UIImage imageWithData:videoFrame];
    });
}

#pragma mark - IBActions

- (IBAction)capture:(id)sender {
    [[MWMultipeerManager sharedManager] sendStringMessage:@"Capture"];
}
- (IBAction)flashlight:(id)sender {
    [[MWMultipeerManager sharedManager] sendStringMessage:@"flashlight"];
}

- (IBAction)shareToFacebook:(id)sender {
    
    if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeSavedPhotosAlbum]){
        NSLog(@"No image picker");
        [[[UIAlertView alloc] initWithTitle:@"No Photo Album"
                                    message:nil
                                   delegate:nil
                          cancelButtonTitle:@"Ok"
                          otherButtonTitles:nil] show];
        return;
    }
    UIImagePickerController *mediaUI = [[UIImagePickerController alloc] init];
    mediaUI.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
    mediaUI.mediaTypes = [UIImagePickerController availableMediaTypesForSourceType:
                          UIImagePickerControllerSourceTypeSavedPhotosAlbum];
    mediaUI.allowsEditing = NO;
    mediaUI.delegate = self;
    [self presentViewController:mediaUI animated:YES completion:nil];
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker
didFinishPickingMediaWithInfo:(NSDictionary *)info {
    
    UIImage *image = info[UIImagePickerControllerOriginalImage];
    
    [self dismissViewControllerAnimated:YES completion:nil];
    
    // Open FB APP to share.
    FBSDKSharePhotoContent* content = [MWFacebookManager shareToFacebook:image];
    [FBSDKShareDialog showFromViewController:self
                                 withContent:content
                                    delegate:self];
    
    //opens popup dialog within our app to share
//    SLComposeViewController *controller = [MWFacebookManager openShareDialog:image];
//    if(controller != nil){
//        [self presentViewController:controller animated:YES completion:Nil];
//    }
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - FBSDKSharingDelegate

- (void)sharer:(id<FBSDKSharing>)sharer didCompleteWithResults:(NSDictionary *)results
{

}
- (void)sharer:(id<FBSDKSharing>)sharer didFailWithError:(NSError *)error
{
    
}
- (void)sharerDidCancel:(id<FBSDKSharing>)sharer
{
    
}

@end
