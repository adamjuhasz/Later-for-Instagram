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

@interface CommentEntryViewController ()
{
    NSArray *searchedTags;
    NSMutableDictionary *expandedTags;
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
    
    [self.hashtagTable registerNib:[UINib nibWithNibName:@"HashtagTableViewCell" bundle:nil] forCellReuseIdentifier:@"hashtag"];
    
    expandedTags = [NSMutableDictionary dictionary];
}

- (void)viewDidAppear:(BOOL)animated
{
    [self.comments becomeFirstResponder];
    self.photoExample.image = thumbnail;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setThumbnail:(UIImage*)aThumbnail
{
    thumbnail = aThumbnail;
}

- (void)setPhoto:(UIImage*)fullsizeImage
{
    fullImage = fullsizeImage;
}

- (NSString*)grabLastHashtagFrom:(NSString*)text {
    NSArray *split = [text componentsSeparatedByString:@" "];
    if (split.count == 0)
        return nil;
    NSString *lastOne = split[split.count-1];
    if (lastOne.length < 2)
        return nil;
    char startChar = [lastOne characterAtIndex:0];
    if (startChar == '#') {
        NSRange firstCharacterIndex = {0,1};
        NSString *tag = [lastOne stringByReplacingCharactersInRange:firstCharacterIndex withString:@""];
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
    newPost.postTime = [NSDate dateWithTimeIntervalSinceNow:10];
    newPost.postImage = fullImage;
    
    [[PostDBSingleton singleton] addPost:newPost];
}

- (void)textViewDidBeginEditing:(UITextView *)textView
{
    [UIView animateWithDuration:0.5 animations:^{
        self.postButton.alpha = 0.0;
        self.doneButton.alpha = 1.0;
    }];
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
    [UIView animateWithDuration:0.5 animations:^{
        self.postButton.alpha = 1.0;
        self.doneButton.alpha = 0.0;
        self.datePicking.alpha = 1.0;
        self.hashtagTable.alpha = 0.0;
    }];
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    NSString *comment = [textView.text stringByReplacingCharactersInRange:range withString:text];
    NSString *hashtag = [self grabLastHashtagFrom:comment];

    if (hashtag.length > 4) {
            //NSLog(@"%@", tag);
            [[InstagramEngine sharedEngine] searchTagsWithName:hashtag
                                                   withSuccess:^(NSArray *tags, InstagramPaginationInfo *paginationInfo) {
                                                       NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
                                                       [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
                                                       for (int i=0; i<tags.count; i++) {
                                                           //InstagramTag *tag = tags[i];
                                                           //NSLog(@"%@ - %@", tag.name, [formatter stringFromNumber:[NSNumber numberWithInteger:tag.mediaCount]]);
                                                       }
                                                       searchedTags = tags;
                                                       [self.hashtagTable reloadData];
                                                       [UIView animateWithDuration:0.5 animations:^{
                                                           self.datePicking.alpha = 0.0;
                                                           self.hashtagTable.alpha = 1.0;
                                                       }];
                                                       
                                                   }
                                                       failure:^(NSError *error) {
                                                           NSLog(@"%@", error);
                                                       }];
    }
    
    if (hashtag == nil && range.length == 0) {
        searchedTags = nil;
        [expandedTags removeAllObjects];
        [self.hashtagTable reloadData];
    }
    
    return YES;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger row = [indexPath row];
    InstagramTag *tag = searchedTags[row];
    
    NSArray *similarTags = [expandedTags objectForKey:tag.name];
    if (similarTags != nil) {
        return 44 + similarTags.count*44;
    }
    
    return 44;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return searchedTags.count;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    HashtagTableViewCell *cell = (id)[tableView dequeueReusableCellWithIdentifier:@"hashtag" forIndexPath:indexPath];

    NSInteger row = [indexPath row];
    InstagramTag *tag = searchedTags[row];
    
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
    
    cell.tagName.text = [NSString stringWithFormat:@"#%@", tag.name];
    cell.tagCount.text = [formatter stringFromNumber:[NSNumber numberWithInteger:tag.mediaCount]];
    
    NSArray *similarTags = [expandedTags objectForKey:tag.name];
    if (similarTags != nil) {
        cell.similarTagArray = similarTags;
        cell.delegate = self;
        [cell.similarTags reloadData];
    };
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger row = [indexPath row];
    NSString *selectedTag = [searchedTags[row] name];
    [self didSelectHashtag:selectedTag atIndexPath:indexPath];
}

- (void)didSelectHashtag:(NSString *)selectedTag atIndexPath:(NSIndexPath*)indexPath
{
    NSString *writtenTag = [self grabLastHashtagFrom:self.comments.text];
    NSString *appendText;
    if (writtenTag != nil) {
        NSRange subRange = [selectedTag rangeOfString:writtenTag];
        int difference = (int)selectedTag.length - (int)subRange.length;
        NSRange substringRange = {writtenTag.length, difference};
        appendText = [selectedTag substringWithRange:substringRange];
    } else {
        appendText = [NSString stringWithFormat:@"#%@", selectedTag];
    }
    NSString *newComment = [NSString stringWithFormat:@"%@%@ ", self.comments.text, appendText];
    self.comments.text = newComment;
    
    [[InstagramEngine sharedEngine] getMediaWithTagName:selectedTag count:50 maxId:0
                                            withSuccess:^(NSArray *media, InstagramPaginationInfo *paginationInfo) {
                                                NSCountedSet *countedTags = [[NSCountedSet alloc] init];
                                                for(int i=0; i<media.count; i++) {
                                                    InstagramMedia *post = media[i];
                                                    NSArray *postTags = post.tags;
                                                    NSMutableSet *postTagSet = [NSMutableSet setWithArray:postTags];
                                                    [postTagSet removeObject:selectedTag];
                                                    [countedTags addObjectsFromArray:postTagSet.allObjects];
                                                }
                                                
                                                NSArray *sortedValues = [countedTags.allObjects sortedArrayUsingComparator:^(id obj1, id obj2) {
                                                    NSUInteger n = [countedTags countForObject:obj1];
                                                    NSUInteger m = [countedTags countForObject:obj2];
                                                    return (n <= m)? (n < m)? NSOrderedDescending : NSOrderedSame : NSOrderedAscending;
                                                }];
                                                
                                                NSMutableArray *similarTagArray = [NSMutableArray array];
                                                for (int i=0; i<MIN(5,sortedValues.count); i++) {
                                                    NSString *hashtagName = sortedValues[i];
                                                    NSNumber *hashtagCount = [NSNumber numberWithUnsignedInteger:[countedTags countForObject:sortedValues[i]]];
                                                    
                                                    if ([countedTags countForObject:sortedValues[i]] <= 2) {
                                                        break;
                                                    }
                                                    
                                                    NSDictionary *tagInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                                                             hashtagName, @"name",
                                                                             hashtagCount, @"count",
                                                                             nil];
                                                    [similarTagArray addObject:hashtagName];
                                                }
                                                [expandedTags setObject:similarTagArray forKey:selectedTag];
                                                if (indexPath) {
                                                    NSArray *indexPaths = [NSArray arrayWithObject:indexPath];
                                                    [self.hashtagTable reloadRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
                                                }
                                                //NSLog(@"%@, %d", similarTagArray, similarTagArray.count);
                                                
                                            } failure:^(NSError *error) {
                                                
                                            }];

}

@end
