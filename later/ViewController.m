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

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [PhotoManager sharedManager];
    [InstagramEngine sharedEngine];
    NSString *accessToken = [[NSUserDefaults standardUserDefaults] objectForKey:@"instagramAccessToken"];
    if (accessToken) {
        [[InstagramEngine sharedEngine] setAccessToken:accessToken];
    }
    
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loginSuccess) name:@"InstagramLoginSuccess" object:nil];
    
    self.progress.trackTintColor = [UIColor clearColor];
    self.progress.progressTintColor = self.view.backgroundColor;
    self.progress.progress = 0.0;
    self.progress.thicknessRatio = 1.0;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if ([[[InstagramEngine sharedEngine] accessToken] isEqualToString:@""] || [[InstagramEngine sharedEngine] accessToken] == nil) {
        self.loginButton.alpha = 0.0;
        self.loginButton.hidden = NO;
        [UIView animateWithDuration:0.3 animations:^{
            self.loginButton.alpha = 1.0;
        }];
    } else {
        [self performSegueWithIdentifier:@"segue.showScheduled" sender:self];
    }
    [self.progress setProgress:1.0 animated:YES initialDelay:0.0 withDuration:5.0];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)loginToInstagram {
    [[InstagramEngine sharedEngine] loginWithBlock:^(NSError *error) {
        if (!error) {
            [[NSUserDefaults standardUserDefaults] setObject:[[InstagramEngine sharedEngine] accessToken] forKey:@"instagramAccessToken"];
        }
    }];
}

- (void)loginSuccess
{
    [self performSegueWithIdentifier:@"segue.showScheduled" sender:self];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
}

@end
