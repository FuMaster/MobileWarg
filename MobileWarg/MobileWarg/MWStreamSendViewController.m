//
//  StreamSendViewController.m
//  MobileWarg
//
//  Created by David Jeong on 2015. 6. 8..
//  Copyright (c) 2015 MobileWarg. All rights reserved.
//

#import "MWMultipeerManager.h"
#import "MWStreamSendViewController.h"
#import "MWMultipeerManager.h"

@interface MWStreamSendViewController ()

@property (weak, nonatomic) IBOutlet UIBarButtonItem *shareBtn;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *scanBtn;
@property (strong, nonatomic) IBOutlet UIView *imageView;
@property (strong, nonatomic) AVCaptureDevice *videoCaptureDevice;
@property (strong, nonatomic) AVCaptureDeviceInput *videoInput;
@property (strong, nonatomic) AVCaptureVideoDataOutput *outputData;
@property (strong, nonatomic) AVCaptureSession *captureSession;
@property (strong, nonatomic) AVCaptureVideoPreviewLayer *previewLayer;
@property (strong, nonatomic) NSOutputStream *outputStream;
@property (assign, nonatomic) BOOL isConnectionEstablished;
@property (strong, nonatomic) NSMutableData *writeDataBuffer;
@property (strong, nonatomic) dispatch_queue_t videoQueue;

- (IBAction)navBarRightButtonPressed:(id)sender;
- (IBAction)sendMessage:(id)sender;
@end

@implementation MWStreamSendViewController

- (void)viewDidLoad {
    
    self.title = @"Mobile Warg";
    
    [super viewDidLoad];
    [self setupMultipeerConnectivity];
    [self setupCamera];
    [self.shareBtn setEnabled:NO];
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
            
            //[self.outputData setSampleBufferDelegate:self queue:dispatch_get_main_queue()];
            self.videoQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
            [self.outputData setSampleBufferDelegate:self queue:self.videoQueue];
            
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
    MWMultipeerManager *manager = [MWMultipeerManager sharedManager];
    [manager setupPeerWithDisplayName:[UIDevice currentDevice].name];
    [manager setupSession];
    [manager advertiseSelf:true];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(connectionStateChange:)
                                                 name:@"MobileWarg_DidChangeStateNotification"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(messageRecived:)
                                                 name:@"MobileWarg_MessageRecivedFromPeer"
                                               object:nil];
    
    
    //if you specify nil for object, you get all the notifications with the matching name, regardless of who sent them
}

- (void)connectionStateChange:(NSNotification *)notification {
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
    
    if ([message isEqualToString:@"wargRequest"]) {
        
        NSString *alertMessage = [NSString stringWithFormat:@"%@ wishes to warg into you",senderPeer.displayName];
        
        [[[UIAlertView alloc] initWithTitle:@"Warg Request"
                                    message:alertMessage
                                   delegate:self
                          cancelButtonTitle:@"Decline"
                          otherButtonTitles:@"Accept", nil] show];
    }
}

- (void)connectionSuccess {
    
    [self.shareBtn setEnabled:YES];
    self.isConnectionEstablished = YES;
    [self.scanBtn setTitle:@"Disconnect"];
    
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
    [self.scanBtn setTitle:@"Connect"];
    [self.shareBtn setEnabled:NO];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)changedOrientation {
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

#pragma mark - VideoStream

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection{
    //Temp
    BOOL isWarg = YES;
    
    if(!isWarg) {
        CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
        //Lock the base address of the pixel buffer
        CVPixelBufferLockBaseAddress(imageBuffer, 0);
        
        //Get the number of bytes per row for the pixel buffer
        size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
        //Get the pixel buffer width and height
        size_t width = CVPixelBufferGetWidth(imageBuffer);
        size_t height = CVPixelBufferGetHeight(imageBuffer);
        
        //Create a device dependent RGB color space
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        
        //Get the base address of the pixel buffer
        void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
        
        CGContextRef newContext = CGBitmapContextCreate(baseAddress, width, height, 8, bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
        CGImageRef newImage = CGBitmapContextCreateImage(newContext);
        CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
        
        //Make UIImage
        UIImage *image = [[UIImage alloc] initWithCGImage:newImage];
        
        //release
        CGContextRelease(newContext);
        CGColorSpaceRelease(colorSpace);
        CGImageRelease(newImage);
        
        MWMultipeerManager * manager = [MWMultipeerManager sharedManager];
        
        if(manager.videoStream && image){
            NSData *imageData = UIImageJPEGRepresentation(image, 0.0);
            //[self writeData:imageData withStream:outStream];
            NSLog(@"imageData size: %lu", (unsigned long)[imageData length]);
            [self writeDataToBuffer:imageData];
        }
    }
}

-(void)writeDataToBuffer:(NSData*)imageData{
    if(self.writeDataBuffer == nil){
        self.writeDataBuffer = [[NSMutableData alloc]init];
    }
    
    MWMultipeerManager * manager = [MWMultipeerManager sharedManager];
    //[self packageDataWithHeader:imageData];
    [self writeData:imageData withStream:manager.videoStream];
}

//-(void)packageDataWithHeader:(NSData*)outgoingData{
//    uint32_t header[1] = {YB_HEADER};
//    uint32_t imageDataLength[1] = {[outgoingData length]};
//    [_writeDataBuffer appendBytes:header length:sizeof(uint32_t)];
//    [_writeDataBuffer appendBytes:imageDataLength length:sizeof(uint32_t)];
//    [_writeDataBuffer appendBytes:[outgoingData bytes] length:[outgoingData length]];
//}

-(void)writeData:(NSData*)imageData withStream:(NSOutputStream*)oStream{
    if([oStream hasSpaceAvailable] && [_writeDataBuffer length] > 0){
        NSLog(@"In write data: has space available");
        NSUInteger length = [_writeDataBuffer length];
        NSUInteger bytesWritten = [oStream write:[_writeDataBuffer bytes] maxLength:length];
        //NSLog(@"bytesWritten: %u", bytesWritten);
        if(bytesWritten == -1){
            NSLog(@"Error writing data");
        }
        else if(bytesWritten > 0){
            [_writeDataBuffer replaceBytesInRange:NSMakeRange(0, bytesWritten) withBytes:NULL length:0];
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

- (IBAction)navBarRightButtonPressed:(id)sender {
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

- (IBAction)sendMessage:(id)sender {
    if (self.isConnectionEstablished) {
        MWMultipeerManager * manager = [MWMultipeerManager sharedManager];
        
        NSData *dataToSend = [@"Send Request" dataUsingEncoding:NSUTF8StringEncoding];
        NSArray *allPeers = manager.session.connectedPeers;
        NSError *error;
        
        [manager.session sendData:dataToSend
                          toPeers:allPeers
                         withMode:MCSessionSendDataReliable
                            error:&error];
    }
}


#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        //Accepted warg request
        NSLog(@"Accepted warg request");
    }
}

@end
