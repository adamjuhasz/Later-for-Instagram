//
//  CommentEntryViewController.m
//  later
//
//  Created by Adam Juhasz on 4/13/15.
//  Copyright (c) 2015 Adam Juhasz. All rights reserved.
//

#import "CommentEntryViewController.h"
#import <InstagramKit/InstagramKit.h>
#import "HashtagTableViewCell.h"
#import "scheduledPostModel.h"
#import "PostDBSingleton.h"
#import "TableViewController.h"

@interface CommentEntryViewController ()
{
    UIImage *thumbnail;
    UIImage *fullImage;
}
@end

@implementation CommentEntryViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self.comments setAutocorrectionType:UITextAutocorrectionTypeNo];
    [self.comments setSpellCheckingType:UITextSpellCheckingTypeYes];
    
    self.ContainerView.translatesAutoresizingMaskIntoConstraints = NO;
    
    /*NSDictionary *views = @{@"view": self.ContainerView,
                            @"top": self.topLayoutGuide };
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"[top][view]" options:0 metrics:nil views:views]];
    self.bottomConstraint = [NSLayoutConstraint constraintWithItem:self.ContainerView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.bottomLayoutGuide attribute:NSLayoutAttributeTop multiplier:1 constant:0];
    [self.view addConstraint:self.bottomConstraint];
    */
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardWillShowNotification object:nil];
    
    if (self.post) {
        self.comments.text = self.post.postCaption;
        [self setThumbnail:self.post.postImage];
        [self setPhoto:self.post.postImage];
        self.DatePickerViewController.datePicker.date = self.post.postTime;
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [self.comments becomeFirstResponder];
    self.photoExample.image = thumbnail;
    
    //reset
    [self.DatePickerViewController resetDate];
}

- (void)setThumbnail:(UIImage*)aThumbnail
{
    thumbnail = aThumbnail;
}

- (void)setPhoto:(UIImage*)fullsizeImage
{
    fullImage = fullsizeImage;
    self.photoExample.image = fullImage;
}

- (NSString*)grabLastHashtagFrom:(NSString*)text {
    NSArray *split = [text componentsSeparatedByString:@" "];
    if (split.count == 0)
        return nil;
    NSString *lastOne = split[split.count-1];
    if (lastOne.length < 2)
        return nil;
    
    //are there more than one hashtag in the mix?
    
    char startChar = [lastOne characterAtIndex:0];
    if (startChar == '#') {
        NSRange firstCharacterIndex = {0,1};
        NSString *tag = [lastOne stringByReplacingCharactersInRange:firstCharacterIndex withString:@""];
        //remove potential puncationaton at the end
        
        return tag;
    }
    return nil;
}

- (IBAction)doneEditing:(id)sender
{
    [self.comments resignFirstResponder];
}

- (IBAction)goBack
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)schedulePost
{
    BOOL newPost = NO;
    if (self.post == nil) {
        self.post = [[scheduledPostModel alloc] init];
        self.post.postImage = fullImage;
        newPost = YES;
    }
    
    self.post.postCaption = self.comments.text;
    self.post.postTime = self.DatePickerViewController.currentDateSelected;
    
    if (newPost) {
        [[PostDBSingleton singleton] addPost:self.post];
    } else {
        //remove and then re-add so if date change we are in the right place in the array
        [[PostDBSingleton singleton] removePost:self.post];
        [[PostDBSingleton singleton] addPost:self.post];
    }
}

- (void)textViewDidBeginEditing:(UITextView *)textView
{
    self.doneButton.hidden = NO;
    self.postButton.hidden = NO;
    
    [UIView animateWithDuration:0.3 animations:^{
        self.doneButton.alpha = 1.0;
        self.postButton.alpha = 0.0;
    }];
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
    self.doneButton.hidden = NO;
    self.postButton.hidden = NO;
    
    [UIView animateWithDuration:0.3 animations:^{
        self.doneButton.alpha = 0.0;
        self.postButton.alpha = 1.0;
    }];
    [self.inputPageController swithToPage:1];
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    NSString *comment = [textView.text stringByReplacingCharactersInRange:range withString:text];
    NSString *hashtag = [self grabLastHashtagFrom:comment];

    if (hashtag.length > 4) {
        [self.tableViewController searchForTag:hashtag];
    } else if (hashtag == nil && range.length == 0) {
        [self.tableViewController clearTable];
    }
    
    return YES;
}

- (void)searchCompleteForHashtag:(NSString *)hashtag
{
    [self.inputPageController swithToPage:0];
}

- (void)didSelectHashtag:(NSString *)selectedTag atIndexPath:(NSIndexPath*)indexPath
{
    NSString *writtenTag = [self grabLastHashtagFrom:self.comments.text];
    NSString *appendText;
    if (writtenTag != nil) {
        NSRange subRange = [selectedTag rangeOfString:writtenTag];
        if (subRange.length > 0) {
            int difference = (int)selectedTag.length - (int)subRange.length;
            NSRange substringRange = {writtenTag.length, difference};
            appendText = [selectedTag substringWithRange:substringRange];
        } else {
            appendText = [NSString stringWithFormat:@" #%@", selectedTag];
        }
    } else {
        appendText = [NSString stringWithFormat:@"#%@", selectedTag];
    }
    NSString *newComment = [NSString stringWithFormat:@"%@%@ ", self.comments.text, appendText];
    self.comments.text = newComment;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"embed.PageController"]) {
        self.tableViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"tableViewController"];
        self.tableViewController.delegate = self;
        
        self.DatePickerViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"DatePickerViewController"];
        
        self.inputPageController = segue.destinationViewController;
        self.inputPageController.pages = @[self.tableViewController, self.DatePickerViewController];
        self.inputPageController.controllerDelegate = self;
    }
}

- (void)keyboardWillHide:(NSNotification *)sender
{
    self.bottomConstraint.constant = 0;
    [self.view layoutIfNeeded];
}

- (void)keyboardDidShow:(NSNotification *)sender
{
    CGRect frame = [sender.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGRect newFrame = [self.view convertRect:frame fromView:[[UIApplication sharedApplication] delegate].window];
    //self.bottomConstraint.constant = newFrame.origin.y - CGRectGetHeight(self.view.frame);
    CGFloat height = (newFrame.origin.y - self.ContainerView.frame.origin.y);
    self.containerHeightConstraint.constant =  height;
    [self.view layoutIfNeeded];
}

- (void)inputPageChangeToPageNumber:(NSInteger)pageNumber
{
    switch (pageNumber) {
        case 0:
            [self.comments becomeFirstResponder];
            break;
        
        case 1:
            [self doneEditing:self];
            break;
            
        default:
            break;
    }
}

@end
