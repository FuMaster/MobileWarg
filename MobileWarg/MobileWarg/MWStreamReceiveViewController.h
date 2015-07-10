//
//  MWStreamReceiveViewController.h
//  MobileWarg
//
//  Created by David Jeong on 2015-06-13.
//  Copyright (c) 2015 MobileWarg. All rights reserved.
//


#import <UIKit/UIKit.h>
#import <MultipeerConnectivity/MultipeerConnectivity.h>
#import "MWMultipeerManager.h"

@interface MWStreamReceiveViewController : UIViewController<MWMultipeerVideoReceiver>

@end
