//
//  HashtagTableViewCell.h
//  later
//
//  Created by Adam Juhasz on 4/13/15.
//  Copyright (c) 2015 Adam Juhasz. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CommentEntryViewController.h"

@interface HashtagTableViewCell : UITableViewCell <UITableViewDataSource, UITableViewDelegate>

@property IBOutlet UILabel *tagName;
@property IBOutlet UILabel *tagCount;
@property IBOutlet UITableView *similarTags;
@property NSArray *similarTagArray;
@property CommentEntryViewController *delegate;

@end
