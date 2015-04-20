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
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(specificDatePicked:)];
        [specificDatw addGestureRecognizer:tap];
    }
}

- (void)specificDatePicked:(UIGestureRecognizer*)tapped
{
    UIView *selectedView = tapped.view;
    selectedView.backgroundColor = [UIColor lightGrayColor];
    NSInteger tag = selectedView.tag;
    
    [self.datePicker setDate:[NSDate dateWithTimeIntervalSinceNow:tag*(60*60)] animated:YES];
}

- (NSDate*)currentDateSelected
{
    return self.datePicker.date;
}

- (void)resetDate
{
    self.datePicker.date = [NSDate dateWithTimeIntervalSinceNow:60*60];
}

@end
