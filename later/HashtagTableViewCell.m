//
//  HashtagTableViewCell.m
//  later
//
//  Created by Adam Juhasz on 4/13/15.
//  Copyright (c) 2015 Adam Juhasz. All rights reserved.
//

#import "HashtagTableViewCell.h"


@implementation HashtagTableViewCell

- (void)prepareForReuse
{
    self.tagName.text = @"";
    self.tagCount.text = @"";
}

@end
