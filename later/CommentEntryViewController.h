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
#import "SchedulesPostsViewController.h"
#import <VBFPopFlatButton/VBFPopFlatButton.h>

@interface CommentEntryViewController : UIViewController <UITextViewDelegate, TableViewControllerDelegate, inputsPageDelegate, LocationHolderDelegate>

@property IBOutlet UITextView *comments;
@property IBOutlet UIImageView *photoExample;

@property IBOutlet VBFPopFlatButton *backButton;
@property IBOutlet VBFPopFlatButton *doneButton;

@property IBOutlet UIView *ContainerView;
@property IBOutlet CaptionInputsPageViewController *inputPageController;
@property IBOutlet TableViewController *tableViewController;
@property IBOutlet DatePickerViewController *DatePickerViewController;
@property IBOutlet MapEmbeddedViewController *locationPickerViewController;
@property IBOutlet NSLayoutConstraint *containerHeightConstraint;
@property IBOutlet UIPageControl *pageControl;

@property (nonatomic, strong) NSLayoutConstraint *bottomConstraint;
@property scheduledPostModel* post;
@property CLLocation *location;
@property CLLocation *initialLocation;

@property IBOutlet UILabel *hashtagCount;

@property SchedulesPostsViewController *delegate;

- (IBAction)goBack;
- (void)didSelectHashtag:(NSString *)selectedTag atIndexPath:(NSIndexPath*)indexPath;
- (void)setThumbnail:(UIImage*)thumbnail;
- (void)setPhoto:(UIImage*)fullsizeImage;
- (IBAction)schedulePost;
- (void)resetView;

@end
