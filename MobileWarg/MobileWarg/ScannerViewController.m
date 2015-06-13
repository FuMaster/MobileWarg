//
//  ViewController.m
//  MobileWarg
//
//  Created by Lawrence Fu on 6/8/15.
//  Copyright (c) 2015 MobileWarg. All rights reserved.
//

#import "ScannerViewController.h"
#import "AppDelegate.h"

@interface ScannerViewController ()

@property (strong, nonatomic) AppDelegate *appDelegate;

@end

@implementation ScannerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    [self.appDelegate.mpcHandler setupPeerWithDisplayName:[UIDevice currentDevice].name];
    [self.appDelegate.mpcHandler setupSession];
    [self.appDelegate.mpcHandler advertiseSelf:true];
    
    [self search];
    
}

- (IBAction)searchForPeers:(id)sender {
    [self search];
}

- (void) search {
    if (self.appDelegate.mpcHandler.session != nil) {
        [[self.appDelegate mpcHandler] setupBrowser];
        [[[self.appDelegate mpcHandler] browser] setDelegate:self];
        
        [self presentViewController:self.appDelegate.mpcHandler.browser
                           animated:YES
                         completion:nil];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark MCBrowserViewController Delegates
- (void)browserViewControllerDidFinish:(MCBrowserViewController *)browserViewController {
    [self.appDelegate.mpcHandler.browser dismissViewControllerAnimated:YES completion:nil];
}

- (void)browserViewControllerWasCancelled:(MCBrowserViewController *)browserViewController {
    [self.appDelegate.mpcHandler.browser dismissViewControllerAnimated:YES completion:nil];
}

@end
