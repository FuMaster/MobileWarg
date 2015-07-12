//
//  MWPreviewViewController.m
//  MobileWarg
//
//  Created by David Jeong on 2015. 6. 8..
//  Copyright (c) 2015 MobileWarg. All rights reserved.
//

#import "MWMultipeerManager.h"
#import "MWPreviewViewController.h"
#import "MWStreamReceiveViewController.h"
#import "UIAlertView+BlocksKit.h"

@interface MWPreviewViewController ()

@property (weak, nonatomic) IBOutlet UIBarButtonItem *wargButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *connectButton;
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
        AVCaptureDevice *videoDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        if(videoDevice) {
            AVCaptureSession *captureSession = [[AVCaptureSession alloc] init];
            
            AVCaptureDeviceInput *videoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:nil];
            [captureSession addInput:videoDeviceInput];
            
            AVCaptureVideoPreviewLayer *previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:captureSession];
            previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
            previewLayer.frame = self.view.frame;
            [self.view.layer addSublayer:previewLayer];
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

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Make sure your segue name in storyboard is the same as this line
    if ([[segue identifier] isEqualToString:@"showStreamReceive"])
    {
        // Get reference to the destination view controller
        MWStreamReceiveViewController *receiveViewController = [segue destinationViewController];
        
        MWMultipeerManager * manger = [MWMultipeerManager sharedManager];
        manger.videoReceiver = receiveViewController;
        manger.isStreaming = YES;
    }
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
