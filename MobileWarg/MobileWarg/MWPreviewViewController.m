//
//  MWPreviewViewController.m
//  MobileWarg
//
//  Created by David Jeong on 2015. 6. 8..
//  Copyright (c) 2015 MobileWarg. All rights reserved.
//

#import "MWPhotoViewController.h"
#import "MWMultipeerManager.h"
#import "MWPreviewViewController.h"
#import "MWStreamReceiveViewController.h"
#import "UIAlertView+BlocksKit.h"

@interface MWPreviewViewController ()

@property (strong, nonatomic) UIImage *image;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *wargButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *connectButton;
@property (strong, nonatomic) AVCaptureVideoPreviewLayer *previewLayer;

@end

@implementation MWPreviewViewController

- (void)viewDidLoad {
    self.title = @"Preview";
    [super viewDidLoad];
    [self setupMultipeerConnectivity];
    [self setupCamera];
    [self.wargButton setEnabled:NO];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(changedOrientation)
                                                 name:UIDeviceOrientationDidChangeNotification
                                               object:nil];
}

- (void)setupCamera {
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        AVCaptureDevice *videoDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        AVCaptureSession *captureSession = [[AVCaptureSession alloc]init];
        if(videoDevice) {
            captureSession = [[AVCaptureSession alloc] init];
            
            AVCaptureDeviceInput *videoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:nil];
            [captureSession addInput:videoDeviceInput];
            
            self.previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:captureSession];
            self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
            self.previewLayer.frame = self.view.frame;
            [self.view.layer addSublayer:self.previewLayer];
            [captureSession startRunning];
            return;
        }
    }
    [[[UIAlertView alloc] initWithTitle:@"No Camera"
                                message:@"There doesn't seem to be a camera on this device"
                               delegate:nil
                      cancelButtonTitle:@"Ok"
                      otherButtonTitles:nil] show];
}

- (void)changedOrientation {
    // Change the fit of the UI element.
    self.previewLayer.frame = self.view.bounds;
    
    UIDeviceOrientation deviceOrientation = [UIDevice currentDevice].orientation;
    
    // Switch statement
    switch (deviceOrientation) {
        case UIInterfaceOrientationLandscapeLeft: {
            [self.previewLayer.connection setVideoOrientation:AVCaptureVideoOrientationLandscapeLeft];
        } break;
        case UIInterfaceOrientationLandscapeRight: {
            [self.previewLayer.connection setVideoOrientation:AVCaptureVideoOrientationLandscapeRight];
        } break;
        case UIInterfaceOrientationPortrait:{
            [self.previewLayer.connection setVideoOrientation:AVCaptureVideoOrientationPortrait];
        } break;
        default:
            break;
    }
}

- (void)setupMultipeerConnectivity {
    //Instantiates MWMultipeerManager
    [MWMultipeerManager sharedManager];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(connectionStateChanged:)
                                                 name:@"MobileWarg_DidChangeStateNotification"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(messageReceived:)
                                                 name:@"MobileWarg_MessageReceivedFromPeer"
                                               object:nil];
    
    //if you specify nil for object, you get all the notifications with the matching name, regardless of who sent them
}

- (void)connectionSuccess {
    [self.wargButton setEnabled:YES];
    [self.connectButton setTitle:@"Disconnect"];
    
    MWMultipeerManager * manager = [MWMultipeerManager sharedManager];
    [manager.browser dismissViewControllerAnimated:YES completion:nil];
    
    [[[UIAlertView alloc] initWithTitle:@"Connected"
                                message:[NSString stringWithFormat:@"Connected to %@",manager.connectedPeerID.displayName]
                               delegate:nil
                      cancelButtonTitle:@"Ok"
                      otherButtonTitles:nil] show];
}

- (void)connectionEnded {
    [self.connectButton setTitle:@"Connect"];
    [self.wargButton setEnabled:NO];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Make sure your segue name in storyboard is the same as this line
    if ([segue.identifier isEqualToString:@"showStreamReceive"]){
        // Get reference to the destination view controller
        MWStreamReceiveViewController *receiveViewController = segue.destinationViewController;
        
        [MWMultipeerManager sharedManager].videoReceiver = receiveViewController;
    }
}

- (IBAction)unwindToPreviewController:(UIStoryboardSegue *)segue {
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - NSNotificationCenter

- (void)connectionStateChanged:(NSNotification *)notification {
    NSDictionary *dict = [notification userInfo];
    NSString *state = [dict valueForKey:@"state"];
    if (state.intValue == MCSessionStateConnected) {
        [self connectionSuccess];
    } else if (state.intValue == MCSessionStateNotConnected) {
        [self connectionEnded];
    }
}

- (void)messageReceived:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    
    MCPeerID *senderPeer = userInfo[@"peer"];
    NSString *message = userInfo[@"message"];
    NSLog(@"Message:%@",message);
    if ([message isEqualToString:@"wargRequest"]) {
        
        NSString *alertMessage = [NSString stringWithFormat:@"%@ wishes to warg into you",senderPeer.displayName];
        
        [UIAlertView bk_showAlertViewWithTitle:@"Warg Request"
                                       message:alertMessage
                             cancelButtonTitle:@"Decline"
                             otherButtonTitles:@[@"Accept"]
                                       handler:^(UIAlertView *alertView, NSInteger buttonIndex) {
                                           if (buttonIndex == 1) {
                                               //Accepted warg request
                                               NSLog(@"Accepting warg request");
                                               [[MWMultipeerManager sharedManager] sendStringMessage:@"wargAccept"];
                                               [self performSegueWithIdentifier:@"showStreamSend" sender:self];
                                           }
                                       }];
        
    } else if ([message isEqualToString:@"wargAccept"]) {
        
        NSString *alertMessage = [NSString stringWithFormat:@"%@ accepted your warg request.",senderPeer.displayName];
        [UIAlertView  bk_showAlertViewWithTitle:@"Warg Accepted"
                                        message:alertMessage
                              cancelButtonTitle:@"Ok"
                              otherButtonTitles:nil
                                        handler:^(UIAlertView *alertView, NSInteger buttonIndex) {
                                            if (buttonIndex == 0) {
                                                //Accepted warg request
                                                NSLog(@"Accepted warg request");
                                                
                                                [self performSegueWithIdentifier:@"showStreamReceive" sender:self];
                                            }
                                        }];
    }
}

#pragma mark - IBActions

- (IBAction)warg:(id)sender {
    [[MWMultipeerManager sharedManager] sendStringMessage:@"wargRequest"];
}

- (IBAction)connect:(id)sender {
    MWMultipeerManager * manager = [MWMultipeerManager sharedManager];
    
    if ([manager.session.connectedPeers count] == 0) {
        manager.browser.delegate = self;
        [self presentViewController:manager.browser
                           animated:YES
                         completion:nil];
    } else {
        [manager.session disconnect];
    }
}

- (IBAction)share:(id)sender {
    [self performSegueWithIdentifier:@"showPhotoDetails" sender:self];
}

#pragma mark - MCBrowserViewControllerDelegate

- (void)browserViewControllerDidFinish:(MCBrowserViewController *)browserViewController {
    MWMultipeerManager * manager = [MWMultipeerManager sharedManager];
    [manager.browser dismissViewControllerAnimated:YES completion:nil];
}

- (void)browserViewControllerWasCancelled:(MCBrowserViewController *)browserViewController {
    MWMultipeerManager * manager = [MWMultipeerManager sharedManager];
    [manager.browser dismissViewControllerAnimated:YES completion:nil];
}

@end
