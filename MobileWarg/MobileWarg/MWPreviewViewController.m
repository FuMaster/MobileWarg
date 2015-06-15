//
//  PreviewViewController.m
//  MobileWarg
//
//  Created by David Jeong on 2015. 6. 8..
//  Copyright (c) 2015 MobileWarg. All rights reserved.
//

#import "MWMultipeerManager.h"
#import "MWPreviewViewController.h"
#import "UIAlertView+BlocksKit.h"

@interface MWPreviewViewController ()

@property (weak, nonatomic) IBOutlet UIBarButtonItem *wargButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *connectButton;
@property (strong, nonatomic) IBOutlet UIView *imageView;
@property (strong, nonatomic) AVCaptureDevice *videoCaptureDevice;
@property (strong, nonatomic) AVCaptureDeviceInput *videoInput;
@property (strong, nonatomic) AVCaptureVideoDataOutput *outputData;
@property (strong, nonatomic) AVCaptureSession *captureSession;
@property (strong, nonatomic) AVCaptureVideoPreviewLayer *previewLayer;
@property (assign, nonatomic) BOOL isConnectionEstablished;

@end

@implementation MWPreviewViewController

- (void)viewDidLoad {
    self.title = @"Preview";
    [super viewDidLoad];
    [self setupMultipeerConnectivity];
    [self setupCamera];
    [self.wargButton setEnabled:NO];
}

- (void)setupCamera {
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        // Create a capture session.
        self.captureSession = [[AVCaptureSession alloc] init];
        self.captureSession.sessionPreset = AVCaptureSessionPresetMedium;
        
        // Add capture device.
        self.videoCaptureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        self.videoInput = [AVCaptureDeviceInput deviceInputWithDevice:self.videoCaptureDevice error:nil];
        
        if (self.videoInput) {
            // If capture device exists.
            self.outputData = [[AVCaptureVideoDataOutput alloc] init];
            self.outputData.videoSettings = @{(NSString *)kCVPixelBufferPixelFormatTypeKey:@(kCVPixelFormatType_32BGRA)};
            
            // Add input and output.
            [self.captureSession addInput:self.videoInput];
            [self.captureSession addOutput:self.outputData];
            
            // Create preview layer.
            self.previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.captureSession];
            self.previewLayer.frame = self.imageView.bounds;
            self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
            
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(changedOrientation)
                                                         name:UIDeviceOrientationDidChangeNotification
                                                       object:nil];
            
            [self.imageView.layer addSublayer:self.previewLayer];
            
            // Start running the capture session.
            [self.captureSession startRunning];
            return;
        }
    }
    
    [[[UIAlertView alloc] initWithTitle:@"No Camera"
                                message:@"There doesn't seem to be a camera on this device"
                               delegate:nil
                      cancelButtonTitle:@"Ok"
                      otherButtonTitles:nil] show];
}

- (void)setupMultipeerConnectivity {
    //Instantiates MWMultipeerManager
    [MWMultipeerManager sharedManager];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(connectionStateChanged:)
                                                 name:@"MobileWarg_DidChangeStateNotification"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(messageRecived:)
                                                 name:@"MobileWarg_MessageRecivedFromPeer"
                                               object:nil];
    
    //if you specify nil for object, you get all the notifications with the matching name, regardless of who sent them
}

- (void)connectionSuccess {
    [self.wargButton setEnabled:YES];
    self.isConnectionEstablished = YES;
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
    self.isConnectionEstablished = NO;
    [self.connectButton setTitle:@"Connect"];
    [self.wargButton setEnabled:NO];
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

- (void)messageRecived:(NSNotification *)notification {
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
                                               MWMultipeerManager * manager = [MWMultipeerManager sharedManager];
                                               [manager sendMessageToConnectedPeer:@"wargAccept"];
                                               
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

-(void)changedOrientation {
    // Change the fit of the UI element.
    self.previewLayer.frame = self.imageView.bounds;
    
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

#pragma mark - IBActions

- (IBAction)warg:(id)sender {
    if (self.isConnectionEstablished) {
        MWMultipeerManager * manager = [MWMultipeerManager sharedManager];
        [manager sendMessageToConnectedPeer:@"wargRequest"];
    }
}

- (IBAction)connect:(id)sender {
    MWMultipeerManager * manager = [MWMultipeerManager sharedManager];
    
    if (self.isConnectionEstablished) {
        if (manager.session != nil) {
            [manager.session disconnect];
        }
    } else {
        if (manager.session != nil) {
            [manager setupBrowser];
            manager.browser.delegate = self;
            
            [self presentViewController:manager.browser
                               animated:YES
                             completion:nil];
        }
    }
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        //Accepted warg request
        NSLog(@"Accepting warg request");
        MWMultipeerManager * manager = [MWMultipeerManager sharedManager];
        [manager sendMessageToConnectedPeer:@"wargAccept"];
        
        [self performSegueWithIdentifier:@"showStreamSend" sender:self];
    }
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
