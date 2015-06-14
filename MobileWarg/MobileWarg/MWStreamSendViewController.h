//
//  MWStreamSendViewController.h
//  MobileWarg
//
//  Created by David Jeong on 2015-06-14.
//  Copyright (c) 2015 MobileWarg. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <MultipeerConnectivity/MultipeerConnectivity.h>

@interface MWStreamSendViewController : UIViewController <
UIAlertViewDelegate,
AVCaptureVideoDataOutputSampleBufferDelegate>

@end
