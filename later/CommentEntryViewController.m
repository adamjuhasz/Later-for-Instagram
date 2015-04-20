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
    
    NSDictionary *views = @{@"view": self.ContainerView,
                            @"top": self.topLayoutGuide };
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"[top][view]" options:0 metrics:nil views:views]];
    self.bottomConstraint = [NSLayoutConstraint constraintWithItem:self.ContainerView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.bottomLayoutGuide attribute:NSLayoutAttributeTop multiplier:1 constant:0];
    [self.view addConstraint:self.bottomConstraint];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardDidShowNotification object:nil];
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
    scheduledPostModel *newPost = [[scheduledPostModel alloc] init];
    newPost.postCaption = self.comments.text;
    newPost.postTime = self.DatePickerViewController.currentDateSelected;
    newPost.postImage = fullImage;
    
    [[PostDBSingleton singleton] addPost:newPost];
}

- (void)textViewDidBeginEditing:(UITextView *)textView
{

}

- (void)textViewDidEndEditing:(UITextView *)textView
{

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
    self.bottomConstraint.constant = newFrame.origin.y - CGRectGetHeight(self.view.frame);
    [self.view layoutIfNeeded];
}

@end
