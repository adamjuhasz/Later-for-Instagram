//
//  LogInotInstagramView.m
//  later
//
//  Created by Adam Juhasz on 5/8/15.
//  Copyright (c) 2015 Adam Juhasz. All rights reserved.
//

#import "LogInotInstagramView.h"
#import <InstagramKit/InstagramKit.h>
#import "NotificationStrings.h"
#import <Localytics/Localytics.h>
#import <ReactiveCocoa/ReactiveCocoa.h>

@implementation LogInotInstagramView

- (void)commonInit
{
    [RACObserve([InstagramEngine sharedEngine], accessToken) subscribeNext:^(NSString *accessToken) {
        if (accessToken == nil) {
            self.hidden = NO;
        } else {
            NSLog(@"token is now alive");
        }
    }];
    if ([[InstagramEngine sharedEngine] accessToken]) {
        self.hidden = YES;
    }
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loginSuccess) name:kLaterInstagramLoginSuccess object:nil];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (IBAction)login:(id)sender
{
    [[InstagramEngine sharedEngine] loginWithBlock:^(NSError *error) {
        if (!error) {
            [[NSUserDefaults standardUserDefaults] setObject:[[InstagramEngine sharedEngine] accessToken] forKey:@"instagramAccessToken"];
        }
    }];
    [Localytics tagEvent:@"InstagramLoginAttempt"];
}

- (void)loginSuccess
{
    self.hidden = YES;
}

@end
