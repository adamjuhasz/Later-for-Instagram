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
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loginSuccess) name:@"InstagramLoginSuccess" object:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
    if ([[[InstagramEngine sharedEngine] accessToken] isEqualToString:@""] || [[InstagramEngine sharedEngine] accessToken] == nil) {
        NSLog(@"not logged in");
    } else {
        [self performSegueWithIdentifier:@"segue.showScheduled" sender:self];
    }
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

@end
