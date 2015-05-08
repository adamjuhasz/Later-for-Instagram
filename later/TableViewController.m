//
//  TableViewController.m
//  later
//
//  Created by Adam Juhasz on 4/19/15.
//  Copyright (c) 2015 Adam Juhasz. All rights reserved.
//

#import "TableViewController.h"
#import <InstagramKit/InstagramKit.h>
#import "HashtagTableViewCell.h"

@interface TableViewController ()
{
    NSString *searchedForTag;
    NSMutableArray *searchedTags;
    NSInteger protectionTag;
}
@end

@implementation TableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.hashtagTable registerNib:[UINib nibWithNibName:@"HashtagTableViewCell" bundle:nil] forCellReuseIdentifier:@"hashtag"];
    
    protectionTag = 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return searchedTags.count;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    HashtagTableViewCell *cell = (id)[tableView dequeueReusableCellWithIdentifier:@"hashtag" forIndexPath:indexPath];
    
    NSInteger row = [indexPath row];
    NSDictionary *tag = searchedTags[row];
    
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
    
    NSInteger indentLevel = [[tag objectForKey:@"indentLevel"] integerValue];
    NSMutableString *indents = [NSMutableString string];
    for (int i=0; i<indentLevel; i++) {
        [indents appendString:@"  "];
    }
    NSString *tagName = [NSString stringWithFormat:@"%@#%@", indents, [tag objectForKey:@"name"]];
    cell.tagName.text = tagName;
    
    NSInteger count = [[tag objectForKey:@"count"] integerValue];
    if (count > 0) {
        NSString *tagCount = [NSString stringWithFormat:@"%@ posts", [formatter stringFromNumber:[NSNumber numberWithInteger:count]]];
        cell.tagCount.text = tagCount;
    }
    
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger row = [indexPath row];
    
    NSDictionary *hashtag = searchedTags[row];
    NSString *selectedTag = [hashtag objectForKey:@"name"];
    NSInteger selectedLocation = [[hashtag objectForKey:@"originalIndex"] integerValue];
    NSInteger indentLevel = [[hashtag objectForKey:@"indentLevel"] integerValue];
    
    [self.delegate didSelectHashtag:selectedTag atIndexPath:indexPath];
    NSInteger protect = protectionTag;
    
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
                                                
                                                NSInteger currentParentLocation = 0;
                                                for(NSDictionary *tag in searchedTags) {
                                                    if ([[tag objectForKey:@"originalIndex"] integerValue] == selectedLocation) {
                                                        currentParentLocation = [searchedTags indexOfObject:tag];
                                                        break;
                                                    }
                                                }
                                                
                                                NSMutableArray *similarTagArray = [NSMutableArray array];
                                                for (int i=0; i<MIN(5,sortedValues.count); i++) {
                                                    if ([countedTags countForObject:sortedValues[i]] <= 2) {
                                                        break;
                                                    }
                                                    
                                                    NSDictionary *similarHashtag = [NSDictionary dictionaryWithObjectsAndKeys:
                                                                             sortedValues[i], @"name",
                                                                             [NSNumber numberWithInteger:0], @"count",
                                                                             [NSNumber numberWithInteger:(selectedLocation+1)*1000+i], @"originalIndex",
                                                                             [NSNumber numberWithInteger:indentLevel + 1], @"indentLevel",
                                                                             nil];
                                                    [similarTagArray addObject:similarHashtag];
                                                }
                                                
                                                
                                                NSRange range = {currentParentLocation+1, similarTagArray.count};
                                                NSIndexSet *indexes = [NSIndexSet indexSetWithIndexesInRange:range];
                                                [searchedTags insertObjects:similarTagArray atIndexes:indexes];
                                                
                                                if (indexPath && protect == protectionTag) { //make sure the table didn't change underneath us from slow internet
                                                    NSMutableArray *indexPaths = [NSMutableArray array];
                                                    for (NSInteger i = 0 ; i<range.length; i++) {
                                                        [indexPaths addObject:[NSIndexPath indexPathForRow:(range.location + i) inSection:0]];
                                                    }
                                                    [self.hashtagTable insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
                                                    
                                                    for (NSDictionary *similarHashtag in searchedTags) {
                                                        [[InstagramEngine sharedEngine] getTagDetailsWithName:[similarHashtag objectForKey:@"name"] withSuccess:^(InstagramTag *tag) {
                                                            NSDictionary *updatedHashtag = [NSDictionary dictionaryWithObjectsAndKeys:
                                                                                            [similarHashtag objectForKey:@"name"], @"name",
                                                                                            [NSNumber numberWithInteger:tag.mediaCount], @"count",
                                                                                            [similarHashtag objectForKey:@"originalIndex"], @"originalIndex",
                                                                                            [similarHashtag objectForKey:@"indentLevel"], @"indentLevel",
                                                                                            nil];
                                                            
                                                            NSInteger index = [searchedTags indexOfObject:similarHashtag];
                                                            [searchedTags replaceObjectAtIndex:index withObject:updatedHashtag];
                                                            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:index inSection:0];
                                                            [self.hashtagTable reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
                                                        } failure:nil];
                                                    }
                                                }
                                            } failure:nil];

}

- (void)searchForTag:(NSString*)hashtag
{
    [self clearTable];
    searchedForTag = hashtag;
    if (![[InstagramEngine sharedEngine] accessToken]) {
        return;
    }
    
    [[InstagramEngine sharedEngine] searchTagsWithName:hashtag
                                           withSuccess:^(NSArray *tags, InstagramPaginationInfo *paginationInfo) {
                                               [self clearTable];
                                               
                                               NSMutableArray *finalTags = [NSMutableArray array];
                                               NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
                                               [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
                                               for (int i=0; i<tags.count; i++) {
                                                   InstagramTag *tag = tags[i];
                                                   if (tag.mediaCount > 1) {
                                                       NSDictionary *hashtagDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                                                                    tag.name, @"name",
                                                                                    [NSNumber numberWithInteger:tag.mediaCount], @"count",
                                                                                    [NSNumber numberWithInteger:i], @"originalIndex",
                                                                                    [NSNumber numberWithInteger:0], @"indentLevel",
                                                                                    nil];
                                                       [finalTags addObject:hashtagDict];
                                                   }
                                               }
                                        
                                               searchedTags = finalTags;
                                               [self.hashtagTable reloadData];
                                               if ([self.hashtagTable numberOfRowsInSection:0] > 0) {
                                                   NSUInteger indexArr[] = {0,0};
                                                   [self.hashtagTable scrollToRowAtIndexPath:[NSIndexPath indexPathWithIndexes:indexArr length:2] atScrollPosition:UITableViewScrollPositionTop animated:YES];
                                               }
                                               [self.delegate searchCompleteForHashtag:hashtag];
                                           }
                                               failure:^(NSError *error) {
                                                   NSLog(@"%@", error);
                                               }];

}

- (void)clearTable
{
    protectionTag++;
    searchedTags = nil;
    [self.hashtagTable reloadData];
}

@end
