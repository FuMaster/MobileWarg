//
//  ViewController.h
//  MobileWarg
//
//  Created by Lawrence Fu on 6/8/15.
//  Copyright (c) 2015 MobileWarg. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MultipeerConnectivity/MultipeerConnectivity.h>

@interface ScannerViewController : UIViewController <MCBrowserViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UIBarButtonItem *scanBtn;

- (IBAction)searchForPeers:(id)sender;

@end

