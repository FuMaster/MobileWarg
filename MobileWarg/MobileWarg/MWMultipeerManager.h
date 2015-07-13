//
//  MWMultipeerManager.h
//  MobileWarg
//
//  Created by Lawrence Fu on 6/8/15.
//  Copyright (c) 2015 MobileWarg. All rights reserved.
//

#import <AssetsLibrary/AssetsLibrary.h>
#import <Foundation/Foundation.h>
#import <MultipeerConnectivity/MultipeerConnectivity.h>

@protocol MWMultipeerVideoReceiver <NSObject>

- (void)receiveImage:(UIImage*)image withFPS:(NSNumber*)fps;

@end

@interface MWMultipeerManager : NSObject <MCSessionDelegate>

@property(nonatomic, strong) MCPeerID *myPeerID;
@property(nonatomic, strong) MCPeerID *connectedPeerID;
@property(nonatomic, strong) MCSession *session;
@property(nonatomic, strong) MCBrowserViewController *browser;
@property(nonatomic, strong) MCAdvertiserAssistant *advertiser;
@property(nonatomic, strong) id<MWMultipeerVideoReceiver> videoReceiver;
@property(nonatomic, assign) BOOL isStreaming;
@property(nonatomic, assign) BOOL isVideo;
@property(nonatomic, strong) UIImage* capturedImage;


+ (id)sharedManager;
- (void)setupPeerWithDisplayName: (NSString *)displayName;
- (void)setupSession;
- (void)setupBrowser;
- (void)advertiseSelf:(BOOL)advertise;
- (void)sendMessageToConnectedPeer:(NSString *)message;

@end
