//
//  DatePickerViewController.m
//  later
//
//  Created by Adam Juhasz on 4/19/15.
//  Copyright (c) 2015 Adam Juhasz. All rights reserved.
//

#import "DatePickerViewController.h"
#import <ReactiveCocoa/ReactiveCocoa.h>

@interface DatePickerViewController ()

@end

@implementation DatePickerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self resetDate];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    for (UIView* specificDatw in self.specificDatePickers) {
        specificDatw.userInteractionEnabled = YES;
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(specificDatePicked:)];
        [specificDatw addGestureRecognizer:tap];
    }
    
    for (int i=0; i<47; i++) {
        arc4random_uniform(30 - 1 + 1);
    }
}

- (void)specificDatePicked:(UIGestureRecognizer*)tapped
{
    UIView *selectedView = tapped.view;
    NSInteger tag = selectedView.tag;
    NSDate *date = [NSDate dateWithTimeIntervalSinceNow:tag*(60*60)];
    
    if (tag == 0) {
        NSCalendar *cal = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
        unsigned int unitFlags = NSCalendarUnitSecond |  NSCalendarUnitMinute  | NSCalendarUnitHour | NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear;
        NSDateComponents *comps = [cal components:unitFlags fromDate:[NSDate date]];
        [comps setHour:(8 + arc4random_uniform(18 - 8 + 1))];
        [comps setMinute:(0 + arc4random_uniform(59 - 0 + 1))];
        [comps setSecond:0];
        date = [cal dateFromComponents:comps];
        date = [date dateByAddingTimeInterval:(60*60*24)*(1 + arc4random_uniform(30 - 1 + 1))];
        
    }
    
    [self.datePicker setDate:date animated:YES];
}

- (NSDate*)currentDateSelected
{
    return self.datePicker.date;
}

- (void)resetDate
{
    self.datePicker.minimumDate = [NSDate date];
    if (self.initialDate && [self.initialDate timeIntervalSinceNow] > 0) {
        self.datePicker.date = self.initialDate;
    } else {
        self.datePicker.date = [NSDate dateWithTimeIntervalSinceNow:60*60];
    }
}

- (void)viewDidLayoutSubviews
{
    [self resetAlpha];
}

- (void)resetAlpha
{
    CGRect dateRect = self.datePicker.frame;
    
    [UIView animateWithDuration:0.2 animations:^{
        BOOL thirdLineOverlapped = NO;
        for (UIView *view in self.thirdLineArray) {
            CGRect viewRect = view.frame;
            thirdLineOverlapped = CGRectIntersectsRect(dateRect, viewRect) | thirdLineOverlapped;
        }
        
        for (UIView *view in self.thirdLineArray) {
            if (thirdLineOverlapped) {
                view.alpha = 0.0;
            } else {
                view.alpha = 1.0;
            }
        }
        
        BOOL secondLineOverlapped = NO;
        for (UIView *view in self.secondLineArray) {
            CGRect viewRect = view.frame;
            secondLineOverlapped = CGRectIntersectsRect(dateRect, viewRect) | secondLineOverlapped;
        }
        
        for (UIView *view in self.secondLineArray) {
            if (secondLineOverlapped) {
                view.alpha = 0.0;
            } else {
                view.alpha = 1.0;
            }
        }
        
        BOOL firstLineOverlapped = NO;
        for (UIView *view in self.firstLineArray) {
            CGRect viewRect = view.frame;
            firstLineOverlapped = CGRectIntersectsRect(dateRect, viewRect) | firstLineOverlapped;
        }
        
        for (UIView *view in self.firstLineArray) {
            if (firstLineOverlapped) {
                view.alpha = 0.0;
            } else {
                view.alpha = 1.0;
            }
        }
    }];
}

@end
