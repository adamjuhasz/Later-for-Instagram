//
//  PostDBSingleton.m
//  later
//
//  Created by Adam Juhasz on 4/15/15.
//  Copyright (c) 2015 Adam Juhasz. All rights reserved.
//

#import "PostDBSingleton.h"
#import <UIKit/UIKit.h>

@interface PostDBSingleton ()
{
    NSMutableArray *arrayOfPosts;
}
@end

@implementation PostDBSingleton

+ (id)singleton
{
    static dispatch_once_t onceToken;
    static PostDBSingleton *singleton = nil;
    dispatch_once(&onceToken, ^{
        singleton = [[self alloc] init];
    });
    return singleton;
}

- (NSString*)filepath
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *completeFilename = [documentsDirectory stringByAppendingPathComponent:@"postDB"];
    return completeFilename;
}

- (id)init
{
    self = [super init];
    if (self) {
        arrayOfPosts = [NSKeyedUnarchiver unarchiveObjectWithFile:[self filepath]];
        if (arrayOfPosts == nil) {
            arrayOfPosts = [NSMutableArray array];
        }
    }
    return self;
}

- (void)save
{
    [NSKeyedArchiver archiveRootObject:arrayOfPosts toFile:[self filepath]];
}

- (void)addPost:(scheduledPostModel*)object
{
    BOOL inserted = NO;
    for (int i=0; i<arrayOfPosts.count; i++) {
        scheduledPostModel *thatPost = arrayOfPosts[i];
        if ([thatPost.postTime compare:object.postTime] == NSOrderedDescending) {
            [arrayOfPosts insertObject:object atIndex:i];
            inserted = YES;
            break;
        }
    }
    if (!inserted)
        [arrayOfPosts addObject:object];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kPostDBUpatedNotification object:self userInfo:[NSDictionary dictionaryWithObject:object forKey:kPostThatWasAddedToSingleton]];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH,0), ^{
        [self registerToSupplyNotifications];
        
        UILocalNotification *theNotification = [[UILocalNotification alloc] init];
        theNotification.fireDate = object.postTime;
        theNotification.timeZone = [NSTimeZone localTimeZone];
        theNotification.alertBody = [NSString stringWithFormat:@"It's time to send \"%@\"", object.postCaption];
        theNotification.alertAction = @"Send";
        theNotification.alertTitle = @"Post scheduled";
        theNotification.applicationIconBadgeNumber = 1;
        theNotification.userInfo = [NSDictionary dictionaryWithObject:object.key forKey:@"key"];
        theNotification.category = @"standard";
        theNotification.soundName = @"TrainStation.wav";
        
        object.postLocalNotification = theNotification;
        [self save];
        
        
        [[UIApplication sharedApplication] scheduleLocalNotification:theNotification];
    });
    
}

- (void)removePost:(scheduledPostModel *)post
{
    [arrayOfPosts removeObject:post];
    NSError *error;
    
    [[NSFileManager defaultManager] removeItemAtPath:post.postImageLocation error:&error];
    
    UILocalNotification *notification = post.postLocalNotification;
    NSArray *notifications = [[UIApplication sharedApplication] scheduledLocalNotifications];
    for (UILocalNotification *aNotification in notifications) {
        NSString *key = [notification.userInfo objectForKey:@"key"];
        if ([key isEqualToString:post.key]) {
            [[UIApplication sharedApplication] cancelLocalNotification:aNotification];
        }
    }
    
    [self save];
    [[NSNotificationCenter defaultCenter] postNotificationName:kPostDBUpatedNotification object:self userInfo:nil];
}

- (NSArray*)allposts
{
    return [arrayOfPosts copy];
}

- (void)registerToSupplyNotifications
{
    UIUserNotificationType types = UIUserNotificationTypeBadge | UIUserNotificationTypeSound | UIUserNotificationTypeAlert;
    
    UIMutableUserNotificationAction *sendAction = [[UIMutableUserNotificationAction alloc] init];
    sendAction.identifier = @"send";
    sendAction.title = @"Send";
    sendAction.activationMode = UIUserNotificationActivationModeForeground;
    sendAction.authenticationRequired = NO;
    sendAction.destructive = NO;
    
    UIMutableUserNotificationAction *snoozeActiom = [[UIMutableUserNotificationAction alloc] init];
    snoozeActiom.identifier = @"snooze";
    snoozeActiom.title = @"Snooze";
    snoozeActiom.activationMode = UIUserNotificationActivationModeBackground;
    snoozeActiom.authenticationRequired = NO;
    snoozeActiom.destructive = NO;
    
    NSArray *standardActions = [NSArray arrayWithObjects:sendAction, snoozeActiom, nil];
    
    UIMutableUserNotificationCategory *standardCategory = [[UIMutableUserNotificationCategory alloc] init];
    standardCategory.identifier = @"standard";
    [standardCategory setActions:standardActions forContext:UIUserNotificationActionContextDefault];
    [standardCategory setActions:standardActions forContext:UIUserNotificationActionContextMinimal];
    
    UIUserNotificationSettings *mySettings = [UIUserNotificationSettings settingsForTypes:types categories:[NSSet setWithObject:standardCategory]];
    
    [[UIApplication sharedApplication] registerUserNotificationSettings:mySettings];
}

- (void)snoozePost:(scheduledPostModel*)post
{
    [self removePost:post];
    
    post.postTime = [post.postTime dateByAddingTimeInterval:60*60];
    [self addPost:post];
}

- (scheduledPostModel*)postForKey:(NSString *)key
{
    for (scheduledPostModel *post in arrayOfPosts) {
        if ([post.key isEqualToString:key]) {
            return post;
        }
    }
    
    return nil;
}

@end
