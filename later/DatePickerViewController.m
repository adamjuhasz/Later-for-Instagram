//
//  DatePickerViewController.m
//  later
//
//  Created by Adam Juhasz on 4/19/15.
//  Copyright (c) 2015 Adam Juhasz. All rights reserved.
//

#import "DatePickerViewController.h"

@interface DatePickerViewController ()

@end

@implementation DatePickerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self resetDate];
    
    for (UIView* specificDatw in self.specificDatePickers) {
        specificDatw.userInteractionEnabled = YES;
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(specificDatePicked:)];
        [specificDatw addGestureRecognizer:tap];
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
    self.datePicker.date = [NSDate dateWithTimeIntervalSinceNow:60*60];
}

@end
