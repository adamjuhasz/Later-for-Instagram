//
//  PostDisplayView.h
//  later
//
//  Created by Adam Juhasz on 5/4/15.
//  Copyright (c) 2015 Adam Juhasz. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <FXBlurView/FXBlurView.h>

@interface PostDisplayView : UIView

@property IBOutlet UIButton *snoozeButton;
@property IBOutlet UIButton *editButton;
@property IBOutlet UIButton *deleteButton;
@property IBOutlet UIButton *sendButton;

@property IBOutlet UIImageView *image;
@property IBOutlet UIView *buttonHolderView;
@property IBOutlet FXBlurView *blurView;

- (void)startGrowing;
- (void)startShrinking;

@end
