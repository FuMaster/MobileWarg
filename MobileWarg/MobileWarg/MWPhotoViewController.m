//
//  MWPhotoViewController.m
//  MobileWarg
//
//

#import "MWFaceDetection.h"
#import "MWFacebookManager.h"
#import "MWPhotoViewController.h"

@interface MWPhotoViewController ()

@property (strong, nonatomic) UIImage *imageWithFace;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (strong, nonatomic) UIImagePickerController *mediaUI;
@property (strong, nonatomic) IBOutlet UITapGestureRecognizer *tapRecognizer;
- (IBAction)goBack:(id)sender;
- (IBAction)selectPhoto:(id)sender;
- (IBAction)tapOnScreen:(id)sender;

@end

@implementation MWPhotoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeSavedPhotosAlbum]){
        NSLog(@"No image picker");
        [[[UIAlertView alloc] initWithTitle:@"No Photo Album"
                                    message:nil
                                   delegate:nil
                          cancelButtonTitle:@"Ok"
                          otherButtonTitles:nil] show];
        return;
    }
    
    [self.imageView setImage:[UIImage imageNamed:@"doge_repeat"]];
    [self.imageView setContentMode:UIViewContentModeLeft];
    [self.imageView setUserInteractionEnabled:YES];
    
    self.mediaUI = [[UIImagePickerController alloc] init];
    self.mediaUI.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
    self.mediaUI.mediaTypes = [UIImagePickerController availableMediaTypesForSourceType:
                          UIImagePickerControllerSourceTypeSavedPhotosAlbum];
    self.mediaUI.allowsEditing = NO;
    self.mediaUI.delegate = self;
    [self presentViewController:self.mediaUI animated:YES completion:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)sharer:(id<FBSDKSharing>)sharer didFailWithError:(NSError *)error {
    NSLog(@"Failed with error.");
}

- (void)sharer:(id<FBSDKSharing>)sharer didCompleteWithResults:(NSDictionary *)results {
    NSLog(@"Sharing succesful.");
}

- (void)sharerDidCancel:(id<FBSDKSharing>)sharer {
    [self dismissViewControllerAnimated:YES completion:nil];
    [self performSegueWithIdentifier:@"unwindToPreviewController" sender:self];
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker
didFinishPickingMediaWithInfo:(NSDictionary *)info {
    
    self.image = info[UIImagePickerControllerOriginalImage];
    [self dismissViewControllerAnimated:YES completion:nil];
    
    MWFaceDetection *detectionManager = [MWFaceDetection detectionManager];
    self.imageWithFace = [detectionManager processImage:self.image];
    
    [self.imageView setImage:self.imageWithFace];
    [self.imageView setContentMode:UIViewContentModeScaleAspectFit];
    [self.tapRecognizer setEnabled:YES];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [self dismissViewControllerAnimated:YES completion:nil];
    [self performSegueWithIdentifier:@"unwindToPreviewController" sender:self];
}

#pragma mark - Actions

- (IBAction)tapOnScreen:(id)sender {
    [self presentViewController:self.mediaUI animated:YES completion:nil];
}

- (IBAction)goBack:(id)sender {
    [self performSegueWithIdentifier:@"unwindToPreviewController" sender:self];
}

- (IBAction)selectPhoto:(id)sender {
    FBSDKSharePhotoContent* content = [MWFacebookManager shareToFacebook:self.image];
    [FBSDKShareDialog showFromViewController:self
                                 withContent:content
                                    delegate:nil];
    
    [self performSegueWithIdentifier:@"unwindToPreviewController" sender:self];
}

@end
