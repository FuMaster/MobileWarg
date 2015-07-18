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

- (void)receiveVideoFrame:(NSDictionary *)videoFrame {
    _fps = videoFrame[@"fps"];
    if (!_playerClock || (_playerClock.timeInterval != (1.0/_fps.floatValue))) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (_playerClock) {
                [_playerClock invalidate];
            }
            
            NSTimeInterval timeInterval = 1.0 / _fps.floatValue;
            _playerClock = [NSTimer scheduledTimerWithTimeInterval:timeInterval
                                                            target:self
                                                          selector:@selector(playerClockTick)
                                                          userInfo:nil
                                                           repeats:YES];
        });
    }
    if ([_frames count] == 0) {
        [_frames addObject:[UIImage imageWithData:videoFrame[@"frame"]]];
    } else {
        [_frames replaceObjectAtIndex:0 withObject:[UIImage imageWithData:videoFrame[@"frame"]]];
    }
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
            
            MWFaceDetection *detectionManager = [MWFaceDetection detectionManager];
            [detectionManager processImage:self.imageView.image];
            
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

- (IBAction)capture:(id)sender {
    MWMultipeerManager * manager = [MWMultipeerManager sharedManager];
    [manager sendStringMessage:@"Capture"];
}

- (IBAction)shareToFacebook:(id)sender {
    
    if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeSavedPhotosAlbum]){
        NSLog(@"No image picker");
        [[[UIAlertView alloc] initWithTitle:@"No Photo Album"
                                    message:nil
                                   delegate:nil
                          cancelButtonTitle:@"Ok"
                          otherButtonTitles:nil] show];
        return;
    }
    UIImagePickerController *mediaUI = [[UIImagePickerController alloc] init];
    mediaUI.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
    mediaUI.mediaTypes = [UIImagePickerController availableMediaTypesForSourceType:
                          UIImagePickerControllerSourceTypeSavedPhotosAlbum];
    mediaUI.allowsEditing = NO;
    mediaUI.delegate = self;
    [self presentViewController:mediaUI animated:YES completion:nil];
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker
didFinishPickingMediaWithInfo:(NSDictionary *)info {
    
    UIImage *image = info[UIImagePickerControllerOriginalImage];
    
    [self dismissViewControllerAnimated:YES completion:nil];
    
    // Open FB APP to share.
    FBSDKSharePhotoContent* content = [MWFacebookManager shareToFacebook:image];
    [FBSDKShareDialog showFromViewController:self
                                 withContent:content
                                    delegate:nil];
}

@end
