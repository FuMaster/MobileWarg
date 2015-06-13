//
//  StreamSendViewController.m
//  MobileWarg
//
//  Created by David Jeong on 2015. 6. 8..
//  Copyright (c) 2015 MobileWarg. All rights reserved.
//

@import AVFoundation;
#import "StreamSendViewController.h"

@interface StreamSendViewController ()
@property (strong, nonatomic) IBOutlet UIView *imageView;

@end

@implementation StreamSendViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Sorry, this application won't work because camera does not exist." delegate:nil cancelButtonTitle:@"Confirm" otherButtonTitles:nil];
        [alert show];
    } else {
        // Create a capture session.
        AVCaptureSession *captureSession = [[AVCaptureSession alloc] init];
        captureSession.sessionPreset = AVCaptureSessionPresetMedium;
        
        // Add capture device.
        AVCaptureDevice *videoCaptureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        AVCaptureDeviceInput *videoInput = [AVCaptureDeviceInput deviceInputWithDevice:videoCaptureDevice error:nil];
        
        if (videoInput) {
            // If capture device exists.
            AVCaptureVideoDataOutput *outputData = [[AVCaptureVideoDataOutput alloc] init];
            outputData.videoSettings = @{(NSString *)kCVPixelBufferPixelFormatTypeKey:@(kCVPixelFormatType_32BGRA)};
            
            // Add input and output.
            [captureSession addInput:videoInput];
            [captureSession addOutput:outputData];
            
            // Create preview layer.
            AVCaptureVideoPreviewLayer *previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:captureSession];
            previewLayer.frame = self.imageView.bounds;
            previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
            [self.imageView.layer addSublayer:previewLayer];
            
            // Start running the capture session.
            [captureSession startRunning];
        } else {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Sorry, video input does not exist." delegate:nil cancelButtonTitle:@"Confirm" otherButtonTitles:nil];
            [alert show];
        }
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
