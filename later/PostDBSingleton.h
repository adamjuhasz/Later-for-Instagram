//
//  PostDBSingleton.h
//  later
//
//  Created by Adam Juhasz on 4/15/15.
//  Copyright (c) 2015 Adam Juhasz. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "scheduledPostModel.h"

#define kPostDBUpatedNotification @"PostDBSingletonAddedPost"
#define kPostThatWasAddedToSingleton @"PostDBPostThatWasAdded"

@interface PostDBSingleton : NSObject

+ (id)singleton;

- (void)addPost:(scheduledPostModel*)post;
- (void)removePost:(scheduledPostModel*)post withDelete:(BOOL)deleteAlso;
- (void)modifyPost:(scheduledPostModel*)post;

- (NSArray*)allposts;
- (void)save;
- (scheduledPostModel*)snoozePost:(scheduledPostModel*)post;
- (scheduledPostModel*)postForKey:(NSString*)key;

@end
