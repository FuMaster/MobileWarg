//
//  MPCHandler.h
//  MobileWarg
//
//  Created by Lawrence Fu on 6/8/15.
//  Copyright (c) 2015 MobileWarg. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MultipeerConnectivity/MultipeerConnectivity.h>

@interface MPCHandler : NSObject <MCSessionDelegate>

@property(nonatomic, strong) MCPeerID *peerID;
@property(nonatomic, strong) MCSession *session;
@property(nonatomic, strong) MCBrowserViewController *browser;
@property(nonatomic, strong) MCAdvertiserAssistant *advertiser;

- (void)setupPeerWithDisplayName: (NSString *)displayName;
- (void)setupSession;
- (void)setupBrowser;
- (void)advertiseSelf: (BOOL)advertise;

@end
