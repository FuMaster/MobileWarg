//
//  MWMultipeerManager.m
//  MobileWarg
//
//  Created by Lawrence Fu on 6/8/15.
//  Copyright (c) 2015 MobileWarg. All rights reserved.
//


#import "MWMultipeerManager.h"
#import "MWStreamReceiveViewController.h"


typedef NS_ENUM(NSInteger, MWDataType) {
    MWDataTypeVideoFrame,
    MWDataTypeCapturedImage,
    MWDataTypeStringMessage
};

@implementation MWMultipeerManager

+ (MWMultipeerManager *)sharedManager {
    static MWMultipeerManager *sharedMyManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[self alloc] init];
    });
    return sharedMyManager;
}

- (id)init {
    if (self = [super init]) {
        [self setupPeerWithDisplayName:[UIDevice currentDevice].name];
        [self setupSession];
        [self advertiseSelf:true];
        [self setupBrowser];
    }
    return self;
}

- (void)setupPeerWithDisplayName:(NSString *)displayName {
    self.myPeerID = [[MCPeerID alloc]  initWithDisplayName:displayName];
}

- (void)setupSession {
    self.session = [[MCSession alloc] initWithPeer:self.myPeerID];
    self.session.delegate = self;
}

- (void)setupBrowser {
    self.browser = [[MCBrowserViewController alloc] initWithServiceType:@"warg"
                                                                session:self.session];
    [self.browser setMaximumNumberOfPeers:1];
}

- (void)advertiseSelf:(BOOL)advertise {
    if (advertise) {
        self.advertiser = [[MCAdvertiserAssistant alloc] initWithServiceType:@"warg"
                                                               discoveryInfo:nil
                                                                     session:self.session];
        [self.advertiser start];
    } else {
        [self.advertiser stop];
        self.advertiser = nil;
    }
}

#pragma mark - Sender Methods

- (void)sendVideoFrame:(NSDictionary *)videoFrame {
    
    NSDictionary *dict = @{@"dataType":@(MWDataTypeVideoFrame),
                           @"data":videoFrame};
    
    [self sendObjectToConnectedPeer:dict];
}

- (void)sendCapturedImage:(UIImage *)capturedImage {
    
    NSDictionary *dict = @{@"dataType":@(MWDataTypeCapturedImage),
                           @"data":capturedImage};
    
    [self sendObjectToConnectedPeer:dict];
}

- (void)sendStringMessage:(NSString *)message {
    
    NSDictionary *dict = @{@"dataType":@(MWDataTypeStringMessage),
                           @"data":message};
    
    [self sendObjectToConnectedPeer:dict];
}

- (void)sendObjectToConnectedPeer:(id)object {
    
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:object];
    
    if (self.connectedPeerID) {
        NSError *error;
        [self.session sendData:data
                       toPeers:@[self.connectedPeerID]
                      withMode:MCSessionSendDataReliable
                         error:&error];
        if (error) {
            NSLog(@"Send Data Failed : %@",[error localizedDescription]);
        }
    } else {
        NSLog(@"Peer not Connected");
    }
}

#pragma mark - MCSessionDelegate

- (void)session:(MCSession *)session
 didReceiveData:(NSData *)archivedData
       fromPeer:(MCPeerID *)peerID {
    
    NSDictionary *dict = (NSDictionary *)[NSKeyedUnarchiver unarchiveObjectWithData:archivedData];
    MWDataType type = [dict[@"dataType"] integerValue];
    id object = dict[@"data"];
    
    switch (type) {
        case MWDataTypeVideoFrame:
            [self.videoReceiver receiveVideoFrame:(NSDictionary*)object];
            break;
            
        case MWDataTypeCapturedImage: {
            UIImage *image = (UIImage *)object;
            [[[ALAssetsLibrary alloc] init] writeImageToSavedPhotosAlbum:[image CGImage]
                                                             orientation:(ALAssetOrientation)[image imageOrientation]
                                                         completionBlock:nil];
            break;
        }
        case MWDataTypeStringMessage: {
            NSString *message = object;
            if( [message isEqualToString:@"Capture"]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"MobileWarg_CaptureImage"
                                                                        object:nil];
                });
            } else {
                NSDictionary *userInfo = @{@"message":message, @"peer":peerID};
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"MobileWarg_MessageReceivedFromPeer"
                                                                        object:nil
                                                                      userInfo:userInfo];
                });
            }
            break;
        }
        default:
            break;
    }
}

- (void)session:(MCSession *)session
           peer:(MCPeerID *)peerID
 didChangeState:(MCSessionState)state {
    switch (state) {
        case MCSessionStateNotConnected: {
            self.connectedPeerID = nil;
            NSDictionary *userInfo = @{@"peerID":peerID, @"state":@(state)};
            dispatch_async(dispatch_get_main_queue(),^{
                NSLog(@"Disconnected");
                [[NSNotificationCenter defaultCenter] postNotificationName:@"MobileWarg_DidChangeStateNotification"
                                                                    object:nil
                                                                  userInfo:userInfo];
            });
        }
            break;
        case MCSessionStateConnecting:
            break;
        case MCSessionStateConnected: {
            self.connectedPeerID = peerID;
            NSDictionary *userInfo = @{@"peerID":peerID, @"state":@(state)};
            dispatch_async(dispatch_get_main_queue(),^{
                NSLog(@"Connected");
                [[NSNotificationCenter defaultCenter] postNotificationName:@"MobileWarg_DidChangeStateNotification"
                                                                    object:nil
                                                                  userInfo:userInfo];
            });
        }
            break;
        default:
            break;
    }
}

- (void)session:(MCSession *)session didReceiveStream:(NSInputStream *)stream
       withName:(NSString *)streamName
       fromPeer:(MCPeerID *)peerID{}

- (void)session:(MCSession *)session didStartReceivingResourceWithName:(NSString *)resourceName
       fromPeer:(MCPeerID *)peerID
   withProgress:(NSProgress *)progress {}

- (void)session:(MCSession *)session didFinishReceivingResourceWithName:(NSString *)resourceName
       fromPeer:(MCPeerID *)peerID
          atURL:(NSURL *)localURL
      withError:(NSError *)error {}
@end

