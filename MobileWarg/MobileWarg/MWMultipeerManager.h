//
//  MPCHandler.h
//  MobileWarg
//
//  Created by Lawrence Fu on 6/8/15.
//  Copyright (c) 2015 MobileWarg. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MultipeerConnectivity/MultipeerConnectivity.h>

@interface MWMultipeerManager : NSObject <MCSessionDelegate>

@property(nonatomic, strong) MCPeerID *myPeerID;
@property(nonatomic, strong) MCPeerID *connectedPeerID;
@property(nonatomic, strong) MCSession *session;
@property(nonatomic, strong) MCBrowserViewController *browser;
@property(nonatomic, strong) NSInputStream *inputStream;
@property(nonatomic, strong) NSOutputStream *outputStream;
@property(nonatomic, strong) MCAdvertiserAssistant *advertiser;

+ (id)sharedManager;
- (void)setupPeerWithDisplayName: (NSString *)displayName;
- (void)setupSession;
- (void)setupBrowser;
- (void)advertiseSelf:(BOOL)advertise;
- (void)sendMessageToConnectedPeer:(NSString *)message;

@end
