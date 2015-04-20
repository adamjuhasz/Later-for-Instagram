//
//  DatePickerViewController.h
//  later
//
//  Created by Adam Juhasz on 4/19/15.
//  Copyright (c) 2015 Adam Juhasz. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CaptionInputsPageViewController.h"

@interface DatePickerViewController : UIViewController

@property IBOutlet UIDatePicker *datePicker;
@property IBOutletCollection(UIView) NSArray* specificDatePickers;

- (NSDate*)currentDateSelected;
- (void)resetDate;

@end
