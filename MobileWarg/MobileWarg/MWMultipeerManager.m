//
//  MPCHandler.m
//  MobileWarg
//
//  Created by Lawrence Fu on 6/8/15.
//  Copyright (c) 2015 MobileWarg. All rights reserved.
//

#import "MWMultipeerManager.h"

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

- (void)setupStream {
    if (self.connectedPeerID) {
        NSError *error;
        self.videoStream = [self.session startStreamWithName:@"wargStream"
                                                      toPeer:self.connectedPeerID
                                                       error:&error];
        if(error){
            NSLog(@"Failed to setuo the output Stream");
        }
    } else {
        NSLog(@"Haven't connected to receiving peer");
    }
}

//Called everytime the connection state of a peer changes
//3 states: not connected, connecting, connected
- (void)session:(MCSession *)session peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state {
    
    switch (state) {
        case MCSessionStateNotConnected: {
            self.connectedPeerID = peerID;
            
            NSDictionary *userInfo = @{@"peerID":peerID, @"state":@(state)};
            dispatch_async(dispatch_get_main_queue(),^{
                NSLog(@"Disconnected");
                [[NSNotificationCenter defaultCenter] postNotificationName:@"MobileWarg_DidChangeStateNotification"
                                                                    object:nil userInfo:userInfo];
            });
        }
            break;
            
        case MCSessionStateConnecting:
            break;
            
        case MCSessionStateConnected: {
            
            self.connectedPeerID = peerID;
            
            NSDictionary *userInfo = @{@"peerID":peerID, @"state":@(state)};
            dispatch_async(dispatch_get_main_queue(),^{
                NSLog(@"Connected to peer");
                [[NSNotificationCenter defaultCenter] postNotificationName:@"MobileWarg_DidChangeStateNotification"
                                                                    object:nil userInfo:userInfo];
            });
            
        }
            break;
            
        default:
            break;
    }
    
    
    
}

//Called whenever device receives data from another peer
- (void)session:(MCSession *)session didReceiveData:(NSData *)data fromPeer:(MCPeerID *)peerID {
    NSDictionary *userInfo = @{ @"data": data,
                                @"peerID": peerID };
    NSString *dataString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    if ([dataString isEqualToString:@"Send Request"]) {
        
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:@"MobileWarg_DidReceiveDataNotification"
                                                            object:nil userInfo:userInfo];
    });
}

//gets called when application has started receiving a resource (ie. file)
//from another peer
- (void)session:(MCSession *)session didStartReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID withProgress:(NSProgress *)progress {
    
}

- (void)session:(MCSession *)session didFinishReceivingResourceWithName:(NSString *)resourceName
       fromPeer:(MCPeerID *)peerID atURL:(NSURL *)localURL withError:(NSError *)error {
    
}

- (void)session:(MCSession *)session didReceiveStream:(NSInputStream *)stream
       withName:(NSString *)streamName fromPeer:(MCPeerID *)peerID {
    
}

@end
