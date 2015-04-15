//
//  HashtagTableViewCell.m
//  later
//
//  Created by Adam Juhasz on 4/13/15.
//  Copyright (c) 2015 Adam Juhasz. All rights reserved.
//

#import "HashtagTableViewCell.h"


@implementation HashtagTableViewCell

- (void)awakeFromNib {
    // Initialization code
    [self.similarTags registerNib:[UINib nibWithNibName:@"HashtagTableViewCell" bundle:nil] forCellReuseIdentifier:@"hashtag"];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.similarTagArray.count;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    HashtagTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"hashtag" forIndexPath:indexPath];
    
    cell.tagName.text = [NSString stringWithFormat:@"#%@", self.similarTagArray[indexPath.row]] ;
    cell.delegate = self.delegate;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger row = indexPath.row;
    NSString *selectedHashtag = self.similarTagArray[row];
    
    [self.delegate didSelectHashtag:selectedHashtag atIndexPath:nil];
}

@end
