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
#import <AudioToolbox/AudioToolbox.h>
#include <sys/types.h>
#include <sys/sysctl.h>
#import <ReactiveCocoa/ReactiveCocoa.h>
#import <Localytics/Localytics.h>

@interface CommentEntryViewController ()
{
    UIImage *thumbnail;
    UIImage *fullImage;
    SystemSoundID clickSound;
}
@end

@implementation CommentEntryViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self.comments setAutocorrectionType:UITextAutocorrectionTypeNo];
    [self.comments setSpellCheckingType:UITextSpellCheckingTypeYes];
    
    self.ContainerView.translatesAutoresizingMaskIntoConstraints = NO;

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardWillShowNotification object:nil];
}

- (void)resetView
{
    //reset caption
    self.comments.text = @"";
    
    self.photoExample.image = thumbnail;
    
    //reset
    [self.DatePickerViewController resetDate];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (self.post) {
        self.comments.text = self.post.postCaption;
        [self setThumbnail:self.post.postImage];
        [self setPhoto:self.post.postImage];
        self.location = self.post.postEditedLocation;
        if ([self.post.postTime timeIntervalSinceNow] > 0) {
            self.DatePickerViewController.initialDate = self.post.postTime;
            [self.DatePickerViewController resetDate];
        }
    } else {
        
    }
    
    //reser table
    [self.tableViewController clearTable];
    
    //set location
    CLLocationCoordinate2D imageLocation = self.location.coordinate;
    MKCoordinateRegion region;
    region.center = imageLocation;
    MKCoordinateSpan span;
    span.latitudeDelta = 0.01;
    span.longitudeDelta = 0.01;
    region.span = span;
    self.locationPickerViewController.mapView.region = region;
}

- (void)didMoveToParentViewController:(UIViewController *)parent
{
    [super didMoveToParentViewController:parent];
    
    if(parent != nil) {
        //show keyboard
        [self.comments becomeFirstResponder];
    }
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

- (BOOL)isHahtag:(NSString*)hashtag
{
    if (hashtag.length < 2)
        return NO;
    
    if ([hashtag characterAtIndex:0] != '#') {
        return NO;
    }
    
    int count = 0;
    for (int i=1; i<hashtag.length; i++) {
        char c = [hashtag characterAtIndex:i];
        if (c == '#') {
            count++;
        }
    }
    if (count > 0) {
        return NO;
    }
    
    return YES;
}

- (NSString*)cleanHashtag:(NSString*)hashtag
{
    NSRange firstCharacter = {0,1};
    NSMutableString *mutableHashtag = [[hashtag stringByReplacingCharactersInRange:firstCharacter withString:@""] mutableCopy];
    
    for (unsigned long i=(mutableHashtag.length-1); i>0; i--) {
        char c = [mutableHashtag characterAtIndex:i];
        if (c == ',' || c == '.' || c == '@' || c == '!' || c == '?') {
            NSRange range = {i , 1};
            [mutableHashtag deleteCharactersInRange:range];
        }
    }
    return mutableHashtag;
}

- (NSArray*)hashtagsInString:(NSString*)string
{
    NSArray *split = [string componentsSeparatedByString:@" "];
    NSMutableArray *hashtags = [split mutableCopy];
    for(int i=0; i<hashtags.count; i++) {
        if ([self isHahtag:hashtags[i]]) {
            NSString *cleanHashtag = [self cleanHashtag:hashtags[i]];
            [hashtags replaceObjectAtIndex:i withObject:cleanHashtag];
        } else {
            [hashtags removeObjectAtIndex:i];
            --i;
        }
    }
    return hashtags;
}

- (NSString*)grabLastHashtagFrom:(NSString*)text {
    NSArray *hashtags = [self hashtagsInString:text];
    
    if (hashtags.count == 0) {
        return nil;
    }
    
    return hashtags[hashtags.count-1];
}

- (IBAction)doneEditing:(id)sender
{
    [self.comments resignFirstResponder];
}

- (IBAction)goBack
{
    [self.delegate popController:self withSuccess:nil];
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
    self.post.postTime = [self.DatePickerViewController.currentDateSelected dateByAddingTimeInterval:10];;
    self.post.postEditedLocation = self.location;
    
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    NSNumber *timeDifference = [NSNumber numberWithDouble:[self.post.postTime timeIntervalSinceNow]];
    [userInfo setObject:timeDifference forKey:@"time"];
    
    if (newPost) {
        [[PostDBSingleton singleton] addPost:self.post];
        [Localytics tagEvent:@"schedulePost" attributes:userInfo];
    } else {
        //remove and then re-add so if date change we are in the right place in the array
        [[PostDBSingleton singleton] removePost:self.post withDelete:NO];
        [[PostDBSingleton singleton] addPost:self.post];
        [Localytics tagEvent:@"editPost" attributes:userInfo];
    }
    
    NSCountedSet *masterSet = [NSCountedSet set];
    
    NSSet *set = [[NSSet alloc] initWithArray:[self hashtagsInString:self.comments.text]];
    for (NSString *hashtag in set) {
        [masterSet addObject:hashtag];
    }
}

- (void)textViewDidBeginEditing:(UITextView *)textView
{
    //if (self.view.frame.size.height == 480) {   //iphone 4
        if (self.doneButton.alpha == 0.0) {
            self.doneButton.hidden = NO;
            self.postButton.hidden = NO;
            
            [UIView animateWithDuration:0.3 animations:^{
                self.doneButton.alpha = 1.0;
                self.postButton.alpha = 0.0;
            }];
        }
    //}
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
    self.doneButton.hidden = NO;
    self.postButton.hidden = NO;
    
    [UIView animateWithDuration:0.3 animations:^{
        self.doneButton.alpha = 0.0;
        self.postButton.alpha = 1.0;
    }];
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    if (self.doneButton.alpha == 0.0) {
        self.doneButton.hidden = NO;
        self.postButton.hidden = NO;
        
        [UIView animateWithDuration:0.3 animations:^{
            self.doneButton.alpha = 1.0;
            self.postButton.alpha = 0.0;
        }];
    }
    
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
            if ([self.comments.text characterAtIndex:(self.comments.text.length-1)] == ' ') {
                appendText = [NSString stringWithFormat:@"#%@", selectedTag];
            } else {
                appendText = [NSString stringWithFormat:@" #%@", selectedTag];
            }
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
        self.DatePickerViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"DatePickerViewController"];
        self.locationPickerViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"locationPickerViewController"];
        
        self.tableViewController.delegate = self;
        self.locationPickerViewController.delegate = self;
        
        if (self.post) {
            self.DatePickerViewController.initialDate = self.post.postTime;
        }
        
        self.inputPageController = segue.destinationViewController;
        self.inputPageController.pages = @[self.tableViewController, self.DatePickerViewController, self.locationPickerViewController];
        self.inputPageController.controllerDelegate = self;
        
        self.pageControl.numberOfPages = self.inputPageController.pages.count;
        self.pageControl.currentPage = MIN((self.pageControl.numberOfPages-1), 1);
    }
}

- (void)keyboardWillHide:(NSNotification *)sender
{
    CGFloat height = (self.view.frame.size.height - self.ContainerView.frame.origin.y);
    //if (height > self.containerHeightConstraint.constant) {
    self.containerHeightConstraint.constant =  height;
    //[self.view layoutIfNeeded];
    //}
}

- (void)keyboardDidShow:(NSNotification *)sender
{
    CGRect frame = [sender.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGRect newFrame = [self.view convertRect:frame fromView:[[UIApplication sharedApplication] delegate].window];
    //self.bottomConstraint.constant = newFrame.origin.y - CGRectGetHeight(self.view.frame);
    CGFloat height = (newFrame.origin.y - self.ContainerView.frame.origin.y);
    //if (height > self.containerHeightConstraint.constant) {
        self.containerHeightConstraint.constant =  height;
        [self.view layoutIfNeeded];
    //}
}

- (void)inputPageChangeToPageNumber:(NSInteger)pageNumber
{
    switch (pageNumber) {
        case 0:
            [Localytics tagEvent:@"showHashtags"];
            [Localytics tagScreen:@"hashtagSearch"];
            [self.comments becomeFirstResponder];
            break;
        
        case 1:
            [self doneEditing:self];
            [Localytics tagScreen:@"schedulePost"];
            break;
            
            case 2:
            [Localytics tagEvent:@"showMap"];
            [self doneEditing:self];
            //set location
            if (self.location) {
                CLLocationCoordinate2D imageLocation = self.location.coordinate;
                MKCoordinateRegion region;
                region.center = imageLocation;
                MKCoordinateSpan span;
                span.latitudeDelta = 0.1;
                span.longitudeDelta = 0.1;
                region.span = span;

                [self.locationPickerViewController.mapView setRegion:region animated:YES];
                [Localytics tagScreen:@"locationSearch"];
            }
            break;
            
        default:
            break;
    }
    self.pageControl.currentPage = pageNumber;
}

@end
