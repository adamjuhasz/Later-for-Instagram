//
//  scheduledPostModel.m
//  later
//
//  Created by Adam Juhasz on 4/15/15.
//  Copyright (c) 2015 Adam Juhasz. All rights reserved.
//

#import "scheduledPostModel.h"

@interface scheduledPostModel ()
{
    UIImage *_postImage;
}
@end

@implementation scheduledPostModel

- (NSString*)postImageLocation
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    return [documentsDirectory stringByAppendingPathComponent:self.key];
}

- (void)setPostImage:(UIImage *)thePostImage
{
    _postImage = thePostImage;
    
    if (self.postImageLocation != nil) {
        //delete old file
    }
    
    NSString *randomFilename = [[[NSUUID UUID] UUIDString] stringByAppendingString:@".igo"];
    self.key = randomFilename;
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *completeFilename = [documentsDirectory stringByAppendingPathComponent:randomFilename];
    NSError *error;
    [UIImageJPEGRepresentation(_postImage, 1.0) writeToFile:completeFilename options:0 error:&error];
    if (error) {
        NSLog(@"%@", error);
    }
}

- (UIImage*)postImage
{
    if (_postImage == nil && self.postImageLocation != nil) {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSString *completeFilename = [documentsDirectory stringByAppendingPathComponent:self.key];
        NSError *error;
        NSData *imageData = [NSData dataWithContentsOfFile:completeFilename options:0 error:&error];
        _postImage = [UIImage imageWithData:imageData];
    }
    return _postImage;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self) {
        self.key = [aDecoder decodeObjectForKey:@"key"];
        self.postTime = [aDecoder decodeObjectForKey:@"postTime"];
        self.postCaption = [aDecoder decodeObjectForKey:@"postCaption"];
        _postImage = [UIImage imageWithContentsOfFile:self.postImageLocation];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.key forKey:@"key"];
    [aCoder encodeObject:self.postTime forKey:@"postTime"];
    [aCoder encodeObject:self.postCaption forKey:@"postCaption"];
}

@end
