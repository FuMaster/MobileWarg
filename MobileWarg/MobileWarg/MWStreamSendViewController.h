//
//  StreamSendViewController.h
//  MobileWarg
//
//  Created by David Jeong on 2015. 6. 8..
//  Copyright (c) 2015 MobileWarg. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <MultipeerConnectivity/MultipeerConnectivity.h>

@interface MWStreamSendViewController : UIViewController <MCBrowserViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UIBarButtonItem *scanBtn;
- (IBAction)searchForPeers:(id)sender;

@end
