//
//  PostDisplayView.m
//  later
//
//  Created by Adam Juhasz on 5/4/15.
//  Copyright (c) 2015 Adam Juhasz. All rights reserved.
//

#import "PostDisplayView.h"
#import <pop/POP.h>
#import <ReactiveCocoa/ReactiveCocoa.h>

@interface PostDisplayView ()
{
    CAGradientLayer *gradient;
}
@end

@implementation PostDisplayView

- (void)awakeFromNib
{
    gradient = [CAGradientLayer layer];
    id colorTop = (id)[[UIColor clearColor] CGColor];
    id colorBottom = (id)[[UIColor colorWithWhite:0.0 alpha:0.9] CGColor];
    gradient.colors = @[colorTop, colorBottom];
    NSNumber *stopTop = [NSNumber numberWithFloat:0.2];
    NSNumber *stopBottom = [NSNumber numberWithFloat:0.9];
    gradient.locations = @[stopTop, stopBottom];
    gradient.frame = self.image.bounds;
    [self.layer insertSublayer:gradient above:self.image.layer];
    
    self.blurView.blurRadius = 5;
    self.blurView.dynamic = NO;
}

- (void)startGrowing
{
    POPBasicAnimation *blurAnimation = [gradient pop_animationForKey:@"blur"];
    if (blurAnimation == nil) {
        blurAnimation = [POPBasicAnimation animationWithPropertyNamed:kPOPViewAlpha];
        [self.blurView pop_addAnimation:blurAnimation forKey:@"blur"];
    }
    blurAnimation.toValue = @(1.0);
    
    POPBasicAnimation *layerAnimation = [gradient pop_animationForKey:@"translate"];
    if (layerAnimation == nil) {
        layerAnimation = [POPBasicAnimation animationWithPropertyNamed:kPOPLayerOpacity];
        [gradient pop_addAnimation:layerAnimation forKey:@"translate"];
    }
    layerAnimation.toValue = @(0.0);
    
    POPBasicAnimation *alphaAnimation = [self.buttonHolderView pop_animationForKey:@"alpha"];
    if (alphaAnimation == nil) {
        alphaAnimation = [POPBasicAnimation animationWithPropertyNamed:kPOPViewAlpha];
        [self.buttonHolderView pop_addAnimation:alphaAnimation forKey:@"alpha"];
    }
    alphaAnimation.toValue = @(1.0);
    
    self.blurView.dynamic = YES;
}

- (void)startShrinking
{
    POPBasicAnimation *blurAnimation = [gradient pop_animationForKey:@"blur"];
    if (blurAnimation == nil) {
        blurAnimation = [POPBasicAnimation animationWithPropertyNamed:kPOPViewAlpha];
        [self.blurView pop_addAnimation:blurAnimation forKey:@"blur"];
    }
    blurAnimation.toValue = @(0.0);
    
    POPBasicAnimation *layerAnimation = [gradient pop_animationForKey:@"translate"];
    if (layerAnimation == nil) {
        layerAnimation = [POPBasicAnimation animationWithPropertyNamed:kPOPLayerOpacity];
        [gradient pop_addAnimation:layerAnimation forKey:@"translate"];
    }
    layerAnimation.toValue = @(1.0);
    
    POPBasicAnimation *alphaAnimation = [self.buttonHolderView pop_animationForKey:@"alpha"];
    if (alphaAnimation == nil) {
        alphaAnimation = [POPBasicAnimation animationWithPropertyNamed:kPOPViewAlpha];
        [self.buttonHolderView pop_addAnimation:alphaAnimation forKey:@"alpha"];
    }
    alphaAnimation.toValue = @(0.0);
    
    self.blurView.dynamic = NO;
}

- (IBAction)snooze:(id)sender
{
    NSLog(@"snooze");
}

@end
