//
//  scheduledPostModel.m
//  later
//
//  Created by Adam Juhasz on 4/15/15.
//  Copyright (c) 2015 Adam Juhasz. All rights reserved.
//

#import "scheduledPostModel.h"
#import <SimpleExif/ExifContainer.h>
#import <SimpleExif/UIImage+Exif.h>
#import <ImageIO/ImageIO.h>

@interface scheduledPostModel ()
{
    UIImage *_postImage;
    CLLocation *_postLocation;
}
@end

@implementation scheduledPostModel

- (id)init
{
    self = [super init];
    if (self) {
        NSString *randomFilename = [[[NSUUID UUID] UUIDString] stringByAppendingString:@".igo"];
        self.key = randomFilename;
    }
    return self;
}

- (NSString*)postImageLocation
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    return [documentsDirectory stringByAppendingPathComponent:self.key];
}

- (void)setPostLocation:(CLLocation *)postLocation
{
    _postLocation = postLocation;
    self.postEditedLocation = postLocation;
}

- (CLLocation*)postLocation
{
    return _postLocation;
}

- (void)saveImage
{
    NSError *error;
    //[UIImageJPEGRepresentation(_postImage, 1.0) writeToFile:self.postImageLocation options:0 error:&error];
    
    ExifContainer *exif = [[ExifContainer alloc] init];
    if (self.postEditedLocation) {
        [exif addLocation:self.postEditedLocation];
    }
    NSData *imageData = [_postImage addExif:exif];
    [imageData writeToFile:self.postImageLocation options:0 error:&error];
    
    if (error) {
        NSLog(@"Error saving file: %@", error);
    }
}

- (void)setPostImage:(UIImage *)thePostImage
{
    _postImage = thePostImage;
    
    //[self saveImage];
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
        _postLocation = [aDecoder decodeObjectForKey:@"postLocation"];
        _postEditedLocation = [aDecoder decodeObjectForKey:@"postEditedLocation"];
        
        NSData *imageData = [NSData dataWithContentsOfFile:self.postImageLocation];
        _postImage = [UIImage imageWithData:imageData];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.key forKey:@"key"];
    [aCoder encodeObject:self.postTime forKey:@"postTime"];
    [aCoder encodeObject:self.postCaption forKey:@"postCaption"];
    [aCoder encodeObject:_postLocation forKey:@"postLocation"];
    [aCoder encodeObject:_postEditedLocation forKey:@"postEditedLocation"];
    [self saveImage];
}

@end
