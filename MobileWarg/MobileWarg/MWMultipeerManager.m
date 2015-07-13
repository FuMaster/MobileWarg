//
//  MWMultipeerManager.m
//  MobileWarg
//
//  Created by Lawrence Fu on 6/8/15.
//  Copyright (c) 2015 MobileWarg. All rights reserved.
//


#import "MWMultipeerManager.h"
#import "MWStreamReceiveViewController.h"

@implementation MWMultipeerManager

+ (id)sharedManager {
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

- (void)sendMessageToConnectedPeer:(NSString *)message {
    
    if (self.connectedPeerID) {
        NSError *error;
        
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:message];
        [self.session sendData:data
                       toPeers:@[self.connectedPeerID]
                      withMode:MCSessionSendDataReliable
                         error:&error];
        if (error) {
            NSLog(@"sendMessageToConnectedPeerError: %@",[error localizedDescription]);
        }
    }
}

#pragma mark - MCSessionDelegate

- (void)session:(MCSession *)session
 didReceiveData:(NSData *)data
       fromPeer:(MCPeerID *)peerID {

    id receivedObject = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    
    // isStreaming is only true for receiver
    if(self.isStreaming) {
        NSDictionary* dict = (NSDictionary*) [NSKeyedUnarchiver unarchiveObjectWithData:data];
        UIImage* image = [UIImage imageWithData:dict[@"image"] scale:2.0];
        NSNumber* framesPerSecond = dict[@"framesPerSecond"];
        [self.videoReceiver receiveImage:image withFPS:framesPerSecond];
        
    } else {
        if ([receivedObject isKindOfClass:[UIImage class]])
        {
            [[[ALAssetsLibrary alloc] init] writeImageToSavedPhotosAlbum:[receivedObject CGImage] orientation:(ALAssetOrientation)[receivedObject imageOrientation] completionBlock:nil];            // save photo to disk.
            [self sendMessageToConnectedPeer:@"sendVideoAgain"];
            self.isStreaming = YES;
        }
        if ([receivedObject isKindOfClass:[NSString class]]) {
            NSString *dataString = receivedObject;
            if ([dataString isEqualToString:@"sendVideoAgain"]) {
                self.isVideo = YES;
            }
            else if( [dataString isEqualToString:@"Capture"]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"MobileWarg_CaptureImage"
                                                                        object: nil];
                });
                
            } else {
                
                NSDictionary *userInfo = @{@"message":dataString,
                                           @"peer":peerID};
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"MobileWarg_MessageReceivedFromPeer"
                                                                        object:nil
                                                                      userInfo:userInfo];
                });
            }
        }
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
