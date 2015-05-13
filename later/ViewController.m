//
//  ViewController.m
//  later
//
//  Created by Adam Juhasz on 4/13/15.
//  Copyright (c) 2015 Adam Juhasz. All rights reserved.
//

#import "ViewController.h"
#import <PhotoManager/PhotoManager.h>
#import <InstagramKit/InstagramKit.h>

@interface ViewController ()
{
    NSTimer *slowPeopleTimer;
}
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [PhotoManager sharedManager];
    [InstagramEngine sharedEngine];
    
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
    
    self.progress.trackTintColor = [UIColor clearColor];
    self.progress.progressTintColor = self.view.backgroundColor;
    self.progress.progress = 0.0;
    self.progress.thicknessRatio = 1.0;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self performSegueWithIdentifier:@"segue.showScheduled" sender:self];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    
}

- (IBAction)loginToInstagram {
    [slowPeopleTimer invalidate];
    [[InstagramEngine sharedEngine] loginWithBlock:^(NSError *error) {
        if (!error) {
            [[NSUserDefaults standardUserDefaults] setObject:[[InstagramEngine sharedEngine] accessToken] forKey:@"instagramAccessToken"];
        }
    }];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
}

@end
