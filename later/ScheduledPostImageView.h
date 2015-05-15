//
//  ScheduledPostImageView.h
//  later
//
//  Created by Adam Juhasz on 5/15/15.
//  Copyright (c) 2015 Adam Juhasz. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ScheduledPostImageView : UIView

@property IBOutlet UILabel *numberTimeLeft;
@property IBOutlet UILabel *unitTimeLeft;
@property IBOutlet UIImageView *imageView;
@property IBOutlet NSLayoutConstraint *bottomConstraint;

- (void)setWithDate:(NSDate*)date;

@end
