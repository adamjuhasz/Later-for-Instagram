//
//  CommentEntryViewController.h
//  later
//
//  Created by Adam Juhasz on 4/13/15.
//  Copyright (c) 2015 Adam Juhasz. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CommentEntryViewController : UIViewController <UITextViewDelegate, UITableViewDataSource, UITableViewDelegate>

@property IBOutlet UITextView *comments;
@property IBOutlet UIImageView *photoExample;
@property IBOutlet UITableView *hashtagTable;
@property IBOutlet UIView *datePicking;
@property IBOutlet UIButton *doneButton;
@property IBOutlet UIButton *postButton;
@property IBOutlet UIDatePicker *datePicker;
@property IBOutletCollection(UIView) NSArray* specificDatePickers;


- (IBAction)goBack;
- (void)didSelectHashtag:(NSString *)selectedTag atIndexPath:(NSIndexPath*)indexPath;
- (void)setThumbnail:(UIImage*)thumbnail;
- (void)setPhoto:(UIImage*)fullsizeImage;
- (IBAction)schedulePost;

@end
