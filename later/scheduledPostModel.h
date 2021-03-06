//
//  scheduledPostModel.h
//  later
//
//  Created by Adam Juhasz on 4/15/15.
//  Copyright (c) 2015 Adam Juhasz. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

@interface scheduledPostModel : NSObject <NSCoding>

@property NSString *key;
@property NSDate *postTime;
@property NSString *postCaption;
@property (readonly) NSString *postImageLocation;
@property UIImage *postImage;
@property CLLocation *postLocation;
@property CLLocation *postEditedLocation;

- (void)saveImage;

@end
