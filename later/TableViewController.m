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
    NSArray *searchedTags;
    NSMutableDictionary *expandedTags;
}
@end

@implementation TableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    expandedTags = [NSMutableDictionary dictionary];
    
    [self.hashtagTable registerNib:[UINib nibWithNibName:@"HashtagTableViewCell" bundle:nil] forCellReuseIdentifier:@"hashtag"];
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger row = [indexPath row];
    InstagramTag *tag = searchedTags[row];
    
    NSArray *similarTags = [expandedTags objectForKey:tag.name];
    if (similarTags != nil) {
        NSLog(@"large size for %ld", (long)indexPath.row);
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
        cell.delegate = (id)self.delegate;
        [cell.similarTags reloadData];
    };
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger row = [indexPath row];
    NSString *selectedTag = [searchedTags[row] name];
    [self.delegate didSelectHashtag:selectedTag atIndexPath:indexPath];
    
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
                                                    
                                                    if ([countedTags countForObject:sortedValues[i]] <= 2) {
                                                        break;
                                                    }
                                                    /*
                                                    NSNumber *hashtagCount = [NSNumber numberWithUnsignedInteger:[countedTags countForObject:sortedValues[i]]];
                                                    NSDictionary *tagInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                                                             hashtagName, @"name",
                                                                             hashtagCount, @"count",
                                                                             nil];
                                                     */
                                                    [similarTagArray addObject:hashtagName];
                                                }
                                                
                                                [expandedTags setObject:similarTagArray forKey:selectedTag];
                                                
                                                if (indexPath) {
                                                    NSArray *indexPaths = [NSArray arrayWithObject:indexPath];
                                                    [self.hashtagTable reloadRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
                                                }
                                                
                                            } failure:^(NSError *error) {
                                                
                                            }];

}

- (void)searchForTag:(NSString*)hashtag
{
    searchedForTag = hashtag;
    [[InstagramEngine sharedEngine] searchTagsWithName:hashtag
                                           withSuccess:^(NSArray *tags, InstagramPaginationInfo *paginationInfo) {
                                               NSMutableArray *finalTags = [NSMutableArray array];
                                               NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
                                               [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
                                               for (int i=0; i<tags.count; i++) {
                                                   InstagramTag *tag = tags[i];
                                                   if (tag.mediaCount > 1) {
                                                       [finalTags addObject:tag];
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
    searchedTags = nil;
    [expandedTags removeAllObjects];
    [self.hashtagTable reloadData];
}

@end
