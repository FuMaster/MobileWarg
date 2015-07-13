//
//  MWStreamSendViewController.m
//  MobileWarg
//
//  Created by David Jeong on 2015-06-14.
//  Copyright (c) 2015 MobileWarg. All rights reserved.
//

#import "MWMultipeerManager.h"
#import "MWStreamSendViewController.h"

@interface MWStreamSendViewController ()
@property (strong, nonatomic) AVCaptureDevice *videoDevice;
@property (strong, nonatomic) AVCaptureSession *videoSession;
@property (strong, nonatomic) AVCaptureDeviceInput *videoInput;
@property (strong, nonatomic) AVCaptureVideoDataOutput *videoDataOutput;
@property (strong, nonatomic) AVCaptureVideoPreviewLayer *videoPreview;
@property (strong, nonatomic) AVCaptureStillImageOutput *stillImageOutput;

@property (assign, nonatomic) BOOL isConnectionEstablished;
@property (strong, nonatomic) NSMutableData *writeDataBuffer;
@end

@implementation MWStreamSendViewController {
    dispatch_queue_t _videoQueue;
}

- (void)viewDidLoad {
    self.title = @"Sending Feed";
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(connectionStateChanged:)
                                                 name:@"MobileWarg_DidChangeStateNotification"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(changedOrientation)
                                                 name:UIDeviceOrientationDidChangeNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(takePhoto:)
                                                 name:@"MobileWarg_CaptureImage"
                                               object:nil];
    
    [self.view layoutSubviews];
    [self setupCamera];
}

- (void)takePhoto:(NSNotification *)notification {
    MWMultipeerManager *manager = [MWMultipeerManager sharedManager];
    manager.isVideo = NO;
    
    [ [self stillImageOutput] captureStillImageAsynchronouslyFromConnection:[ [self stillImageOutput] connectionWithMediaType:AVMediaTypeVideo] completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
        
        if (imageDataSampleBuffer)
        {
            NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
            UIImage *image = [[UIImage alloc] initWithData:imageData];
            [[[ALAssetsLibrary alloc] init] writeImageToSavedPhotosAlbum:[image CGImage] orientation:(ALAssetOrientation)[image imageOrientation] completionBlock:nil];
            
            NSData *finalData = [NSKeyedArchiver archivedDataWithRootObject:image];
            
            if (!manager.isVideo && manager.connectedPeerID) {
                NSLog(@"Taking photo.");
                [manager.session sendData:finalData toPeers:@[manager.connectedPeerID] withMode:MCSessionSendDataReliable error:nil];
            } else {
                NSLog(@"Not sending photo");
            }

            
        }
    }];
}

- (void)setupCamera {
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        
        self.videoDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        
        if(self.videoDevice) {
            self.videoSession = [[AVCaptureSession alloc] init];
            
            self.videoInput = [AVCaptureDeviceInput deviceInputWithDevice:self.videoDevice error:nil];
            [self.videoSession addInput:self.videoInput];
            
            self.videoPreview = [AVCaptureVideoPreviewLayer layerWithSession:self.videoSession];
            
            self.videoPreview.videoGravity = AVLayerVideoGravityResizeAspectFill;
            self.videoPreview.frame = self.view.frame;
            [self.view.layer addSublayer:self.videoPreview];
            
            self.videoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
            
            _videoQueue = dispatch_queue_create("com.mobilewarg.videoSenderQueue", DISPATCH_QUEUE_SERIAL);
            [self.videoDataOutput setSampleBufferDelegate:self queue:_videoQueue];
            self.videoDataOutput.alwaysDiscardsLateVideoFrames = YES;
            
            [self.videoSession addOutput:self.videoDataOutput];
            
            AVCaptureStillImageOutput *stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
            if ([self.videoSession canAddOutput:stillImageOutput])
            {
                [stillImageOutput setOutputSettings:@{AVVideoCodecKey : AVVideoCodecJPEG}];
                [self.videoSession addOutput:stillImageOutput];
                [self setStillImageOutput:stillImageOutput];
            }
            
            
            [self.videoSession startRunning];
            return;
        }
    }
    
    [[[UIAlertView alloc] initWithTitle:@"No Camera"
                                message:@"There doesn't seem to be a camera on this device"
                               delegate:nil
                      cancelButtonTitle:@"Ok"
                      otherButtonTitles:nil] show];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - NSNotificationCenter

- (void) connectionStateChanged:(NSNotification *)notification {
    NSDictionary *dict = [notification userInfo];
    NSString *state = [dict valueForKey:@"state"];
    if (state.intValue == MCSessionStateNotConnected) {
        //go back to last page
    }
}

- (void) changedOrientation {
    // Change the fit of the UI element.
    self.videoPreview.frame = self.view.bounds;
    
    UIDeviceOrientation deviceOrientation = [UIDevice currentDevice].orientation;
    
    // Switch statement
    switch (deviceOrientation) {
        case UIInterfaceOrientationLandscapeLeft: {
            [self.videoPreview.connection setVideoOrientation:AVCaptureVideoOrientationLandscapeLeft];
        } break;
        case UIInterfaceOrientationLandscapeRight: {
            [self.videoPreview.connection setVideoOrientation:AVCaptureVideoOrientationLandscapeRight];
        } break;
        case UIInterfaceOrientationPortrait:{
            [self.videoPreview.connection setVideoOrientation:AVCaptureVideoOrientationPortrait];
        } break;
        default:
            break;
    }
}

#pragma mark - VideoStream

- (void)captureOutput:(AVCaptureOutput *)captureOutput
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection {
    
    NSNumber* timestamp = @(CMTimeGetSeconds(CMSampleBufferGetPresentationTimeStamp(sampleBuffer)));
    
    CVImageBufferRef cvImage = CMSampleBufferGetImageBuffer(sampleBuffer);
    CGRect cropRect = AVMakeRectWithAspectRatioInsideRect(CGSizeMake(569, 320), CGRectMake(0,0, CVPixelBufferGetWidth(cvImage),CVPixelBufferGetHeight(cvImage)) );
    CIImage *ciImage = [[CIImage alloc] initWithCVPixelBuffer:cvImage];
    CIImage* croppedImage = [ciImage imageByCroppingToRect:cropRect];
    
    CIFilter *scaleFilter = [CIFilter filterWithName:@"CILanczosScaleTransform"];
    [scaleFilter setValue:croppedImage forKey:@"inputImage"];
    [scaleFilter setValue:[NSNumber numberWithFloat:0.25] forKey:@"inputScale"];
    [scaleFilter setValue:[NSNumber numberWithFloat:1.0] forKey:@"inputAspectRatio"];
    CIImage *finalImage = [scaleFilter valueForKey:@"outputImage"];
    UIImage* cgBackedImage = [self cgImageBackedImageWithCIImage:finalImage];
    
    NSData *imageData = UIImageJPEGRepresentation(cgBackedImage,0.2);
    
    // maybe not always the correct input?  just using this to send current FPS...
    
    AVCaptureInputPort* inputPort = connection.inputPorts[0];
    AVCaptureDeviceInput* deviceInput = (AVCaptureDeviceInput*) inputPort.input;
    CMTime frameDuration = deviceInput.device.activeVideoMaxFrameDuration;
    NSDictionary* dict = @{
                           @"image": imageData,
                           @"timestamp" : timestamp,
                           @"framesPerSecond": @(frameDuration.timescale)
                           };
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:dict];
    
    MWMultipeerManager * manager = [MWMultipeerManager sharedManager];
    
    if (manager.isVideo && manager.connectedPeerID) {
        NSLog(@"Sending video");
        [manager.session sendData:data toPeers:@[manager.connectedPeerID] withMode:MCSessionSendDataReliable error:nil];
    } else {
        NSLog(@"Not sending video");
    }
}

- (UIImage*) cgImageBackedImageWithCIImage:(CIImage*) ciImage {
    
    CIContext *context = [CIContext contextWithOptions:nil];
    CGImageRef ref = [context createCGImage:ciImage fromRect:ciImage.extent];
    UIImage* image = [UIImage imageWithCGImage:ref scale:[UIScreen mainScreen].scale orientation:UIImageOrientationRight];
    CGImageRelease(ref);
    
    return image;
}

@end
