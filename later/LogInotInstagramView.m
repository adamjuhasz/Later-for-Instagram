//
//  LogInotInstagramView.m
//  later
//
//  Created by Adam Juhasz on 5/8/15.
//  Copyright (c) 2015 Adam Juhasz. All rights reserved.
//

#import "LogInotInstagramView.h"
#import <InstagramKit/InstagramKit.h>

@implementation LogInotInstagramView

- (void)commonInit
{
    if ([[InstagramEngine sharedEngine] accessToken]) {
        self.hidden = YES;
    }
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
}

@end
