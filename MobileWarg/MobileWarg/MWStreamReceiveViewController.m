//
//  MWStreamReceiveViewController.m
//  MobileWarg
//
//  Created by David Jeong on 2015-06-13.
//  Copyright (c) 2015 MobileWarg. All rights reserved.
//

#import "MWStreamReceiveViewController.h"
#import <FBSDKShareKit/FBSDKShareKit.h>
#import "MWFacebookManager.h"

@import Social;

@interface MWStreamReceiveViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *shareButton;

@end

@implementation MWStreamReceiveViewController {
    BOOL _isPlaying;
    NSMutableArray* _frames;
    NSTimer* _playerClock;
    NSIndexPath* _indexPath;
    NSNumber* _fps;
    NSInteger _numberOfFramesAtLastTick;
    NSInteger _numberOfTicksWithFullBuffer;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Receiving Feed";
    
    _frames = [[NSMutableArray alloc] init];
    _isPlaying = NO;
    _numberOfTicksWithFullBuffer = 0;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - MWMultipeerVideoReceiver

- (void)receiveImage:(UIImage*)image withFPS:(NSNumber*)fps{
    _fps = fps;
    if (!_playerClock || (_playerClock.timeInterval != (1.0/fps.floatValue))) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (_playerClock) {
                [_playerClock invalidate];
            }
            
            NSTimeInterval timeInterval = 1.0 / [fps floatValue];
            _playerClock = [NSTimer scheduledTimerWithTimeInterval:timeInterval
                                                            target:self
                                                          selector:@selector(playerClockTick)
                                                          userInfo:nil
                                                           repeats:YES];
        });
    }
    [_frames addObject:image];

}


// If using auto-framerate (self.useAutoFramerate == YES)
// AUTO LOWER FRAMERATE BASED ON CONNECTION SPEED TO MATCH SENDER
// Every clock tick, if playing: if the number of buffered frames goes down
//      then send a msg saying to lower the framerate
// else every 5th clocktick if it has stayed the same
//      then send a msg saying to raise the framerate
- (void) playerClockTick {
    
    //NSInteger delta = _frames.count - _numberOfFramesAtLastTick;
    //NSLog(@"(%@) fps: %f frames total: %d  frames@last: %d delta: %d", _peerID.displayName, _fps.floatValue, _frames.count, _numberOfFramesAtLastTick, delta);
    _numberOfFramesAtLastTick = _frames.count;
    if (_isPlaying) {
        
        if (_frames.count > 1) {
            
            
//            if (self.useAutoFramerate) {
//                if (_frames.count >= 10) {
//                    if (_numberOfTicksWithFullBuffer >= 30) {
//                        // higher framerate
//                        if (self.delegate) {
//                            [self.delegate raiseFramerateForPeer:_peerID];
//                        }
//                        _numberOfTicksWithFullBuffer = 0;
//                    }
//                    
//                    _numberOfTicksWithFullBuffer++;
//                } else {
//                    _numberOfTicksWithFullBuffer = 0;
//                    if (delta <= -1) {
//                        // lower framerate
//                        if (self.delegate && _fps.floatValue > 5) {
//                            [self.delegate lowerFramerateForPeer:_peerID];
//                        }
//                    }
//                }
//            }
            
            self.imageView.image = _frames[0];
            [_frames removeObjectAtIndex:0];
            
            
        } else {
            _isPlaying = NO;
        }
    } else {
        if (_frames.count > 10) {
            _isPlaying = YES;
        }
    }
}

- (void) stopPlaying {
    if (_playerClock) {
        [_playerClock invalidate];
    }
}

#pragma mark - IBActions
- (IBAction)shareToFacebook:(id)sender {
    UIGraphicsBeginImageContextWithOptions(self.view.bounds.size, self.view.opaque, 0.0);
    [self.view.layer renderInContext:UIGraphicsGetCurrentContext()];
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    FBSDKSharePhotoContent* content = [MWFacebookManager shareToFacebook:image];
    [FBSDKShareDialog showFromViewController:self
                                 withContent:content
                                    delegate:nil];
    
//    SLComposeViewController *controller = [MWFacebookManager openShareDialog:image];
//    if(controller != nil){
//        [self presentViewController:controller animated:YES completion:Nil];
//    }
}


@end
