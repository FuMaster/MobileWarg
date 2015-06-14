//
//  MWStreamReceiveViewController.m
//  MobileWarg
//
//  Created by David Jeong on 2015-06-13.
//  Copyright (c) 2015 MobileWarg. All rights reserved.
//

#import "MWStreamReceiveViewController.h"
#import "MWMultipeerManager.h"

@interface MWStreamReceiveViewController ()
@property (strong, nonatomic) IBOutlet UIView *imageView;
@property (strong, nonatomic) NSMutableData *data;
@property (strong, nonatomic) NSInputStream *inputStream;
@property (strong, nonatomic) NSData *videoStream;


@end

@implementation MWStreamReceiveViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/
- (void)setUpStream:(NSString *)path {
    // iStream is NSInputStream instance variable
    [self.inputStream setDelegate:self];
    [self.inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop]
                       forMode:NSDefaultRunLoopMode];
    [self.inputStream open];
}

- (void)stream:(NSStream *)stream handleEvent:(NSStreamEvent)eventCode {
    switch(eventCode) {
        case NSStreamEventHasBytesAvailable:
        {
            uint8_t buffer[1024];
            unsigned int len = 0;
            while ([self.inputStream hasBytesAvailable]) {
                len = [self.inputStream read:buffer maxLength:sizeof(buffer)];
                NSLog(@"len=%d", len);
                if (len > 0) {
                    [self.data appendBytes:(const void *)buffer length:len];
                }
            }
            UIImageView *view = [[UIImageView alloc] init];
            [self.imageView addSubview:view];
            UIImage *image = [[UIImage alloc]initWithData:self.data];
            [view setImage:image];
            
            break;
        }
        default:
        {
            break;
        }
    }
}

@end
