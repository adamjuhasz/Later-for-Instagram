//
//  ScheduledPostImageView.m
//  later
//
//  Created by Adam Juhasz on 5/15/15.
//  Copyright (c) 2015 Adam Juhasz. All rights reserved.
//

#import "ScheduledPostImageView.h"
#import <CoreText/CoreText.h>

@interface ScheduledPostImageView ()
{
    CAGradientLayer *gradient;
}
@end

@implementation ScheduledPostImageView

- (void)commonInit
{
    gradient = [CAGradientLayer layer];
    id colorTop = (id)[[UIColor clearColor] CGColor];
    id colorBottom = (id)[[UIColor colorWithWhite:0.0 alpha:0.5] CGColor];
    gradient.colors = @[colorTop, colorBottom];
    NSNumber *stopTop = [NSNumber numberWithFloat:0.2];
    NSNumber *stopBottom = [NSNumber numberWithFloat:0.9];
    gradient.locations = @[stopTop, stopBottom];
    gradient.frame = self.bounds;
    [self.layer insertSublayer:gradient above:self.imageView.layer];
}

- (void)awakeFromNib
{
    [self commonInit];
}

-(void)layoutSubviews{
    gradient.frame = self.layer.bounds;
}

- (void)setWithDate:(NSDate*)dateToBe
{
    // Get the system calendar
    NSCalendar *sysCalendar = [NSCalendar currentCalendar];
    
    // Create the NSDates
    NSDate *currentDate = [[NSDate alloc] init];
    
    // Get conversion to months, days, hours, minutes
    unsigned int unitFlags = NSCalendarUnitSecond |  NSCalendarUnitMinute  | NSCalendarUnitHour | NSCalendarUnitDay | NSCalendarUnitMonth;
    NSDateComponents *breakdownInfo = [sysCalendar components:unitFlags fromDate:currentDate  toDate:dateToBe  options:0];
    //NSLog(@"Break down: %ld sec : %ld min : %ld hours : %ld days : %ld months", [breakdownInfo second], [breakdownInfo minute], [breakdownInfo hour], [breakdownInfo day], [breakdownInfo month]);

    
    UIFontDescriptor *const existingDescriptor = [self.numberTimeLeft.font fontDescriptor];
    NSDictionary *const fontAttributes = @{
                                           // Here comes that array of dictionaries each containing UIFontFeatureTypeIdentifierKey
                                           // and UIFontFeatureSelectorIdentifierKey that the reference mentions.
                                           UIFontDescriptorFeatureSettingsAttribute: @[
                                                   @{
                                                       UIFontFeatureTypeIdentifierKey: @(kNumberSpacingType),
                                                       UIFontFeatureSelectorIdentifierKey: @(kProportionalNumbersSelector)
                                                       }]
                                           };
    
    UIFontDescriptor *const proportionalDescriptor = [existingDescriptor fontDescriptorByAddingAttributes: fontAttributes];
    self.numberTimeLeft.font = [UIFont fontWithDescriptor: proportionalDescriptor size: [self.numberTimeLeft.font pointSize]];
    
    if (ABS(breakdownInfo.month) > 0) {
        self.numberTimeLeft.text = [NSString stringWithFormat:@"%ld", (long)ABS(breakdownInfo.month)];
        self.unitTimeLeft.text = @"month";
    } else if (ABS(breakdownInfo.day) > 0) {
        self.numberTimeLeft.text = [NSString stringWithFormat:@"%ld", (long)ABS(breakdownInfo.day)];
        self.unitTimeLeft.text = @"day";
    } else if (ABS(breakdownInfo.hour) > 0) {
        self.numberTimeLeft.text = [NSString stringWithFormat:@"%ld", (long)ABS(breakdownInfo.hour)];
        self.unitTimeLeft.text = @"hour";
    } else if (ABS(breakdownInfo.minute) > 0) {
        self.numberTimeLeft.text = [NSString stringWithFormat:@"%ld", (long)ABS(breakdownInfo.minute)];
        self.unitTimeLeft.text = @"minute";
    } else {
        self.numberTimeLeft.text = @"Soon";
        self.unitTimeLeft.hidden = YES;
        self.bottomConstraint.constant = 8;
    }
    
    NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
    f.numberStyle = NSNumberFormatterDecimalStyle;
    NSNumber *myNumber = [f numberFromString:self.numberTimeLeft.text];
    if (myNumber && [myNumber integerValue] > 1) {
        self.unitTimeLeft.text  = [NSString stringWithFormat:@"%@s", self.unitTimeLeft.text];
    }
    
    if ([dateToBe compare:currentDate] == NSOrderedDescending) {
        //nothing
    } else {
        if ([self.numberTimeLeft.text isEqualToString:@"Soon"]) {
            self.numberTimeLeft.text = @"Now";
        } else {
            self.unitTimeLeft.text = [NSString stringWithFormat:@"%@ late", self.unitTimeLeft.text];
        }
    }
}

@end
