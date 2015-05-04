//
//  CommentEntryViewController.h
//  later
//
//  Created by Adam Juhasz on 4/13/15.
//  Copyright (c) 2015 Adam Juhasz. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CaptionInputsPageViewController.h"
#import "TableViewController.h"
#import "DatePickerViewController.h"
#import "scheduledPostModel.h"
#import <CoreLocation/CoreLocation.h>
#import "MapEmbeddedViewController.h"

@interface CommentEntryViewController : UIViewController <UITextViewDelegate, TableViewControllerDelegate, inputsPageDelegate>

@property IBOutlet UITextView *comments;
@property IBOutlet UIImageView *photoExample;

@property IBOutlet UIButton *doneButton;
@property IBOutlet UIButton *postButton;

@property IBOutlet UIView *ContainerView;
@property IBOutlet CaptionInputsPageViewController *inputPageController;
@property IBOutlet TableViewController *tableViewController;
@property IBOutlet DatePickerViewController *DatePickerViewController;
@property IBOutlet MapEmbeddedViewController *locationPickerViewController;
@property IBOutlet NSLayoutConstraint *containerHeightConstraint;

@property (nonatomic, strong) NSLayoutConstraint *bottomConstraint;
@property scheduledPostModel* post;
@property CLLocation *location;

- (IBAction)goBack;
- (void)didSelectHashtag:(NSString *)selectedTag atIndexPath:(NSIndexPath*)indexPath;
- (void)setThumbnail:(UIImage*)thumbnail;
- (void)setPhoto:(UIImage*)fullsizeImage;
- (IBAction)schedulePost;
- (void)resetView;

@end
