//
//  PostDBSingleton.m
//  later
//
//  Created by Adam Juhasz on 4/15/15.
//  Copyright (c) 2015 Adam Juhasz. All rights reserved.
//

#import "PostDBSingleton.h"
#import <UIKit/UIKit.h>

#define SaveTimerTime 5.0

@interface UIImage (deepCopy)
- (UIImage*)deepCopy;
@end

@implementation UIImage (deepCopy)

- (UIImage*)deepCopy
{
    CGImageRef newCgIm = CGImageCreateCopy(self.CGImage);
    UIImage *copy = [UIImage imageWithCGImage:newCgIm
                                        scale:self.scale
                                  orientation:self.imageOrientation];
    return copy;
}

@end

@interface PostDBSingleton ()
{
    NSMutableArray *arrayOfPosts;
    NSTimer *saveTimer;
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
        } else {
            for (int i=0; i<arrayOfPosts.count; i++) {
                scheduledPostModel *post = [arrayOfPosts objectAtIndex:i];
                if (post.postImage == nil) {
                    [arrayOfPosts removeObjectAtIndex:i];
                    i--;
                }
            }
        }
    }
    return self;
}

- (void)save
{
    [NSKeyedArchiver archiveRootObject:arrayOfPosts toFile:[self filepath]];
    NSLog(@"save done");
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
    
    if (saveTimer) {
        [saveTimer invalidate];
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH,0), ^{
        [self registerToSupplyNotifications];
        
        UILocalNotification *theNotification = [[UILocalNotification alloc] init];
        theNotification.fireDate = object.postTime;
        theNotification.timeZone = [NSTimeZone localTimeZone];
        theNotification.alertBody = [NSString stringWithFormat:@"It's time to send \"%@\"", object.postCaption];
        theNotification.alertAction = @"Send";
        if ([theNotification respondsToSelector:@selector(setAlertTitle:)]) {
            //only ios 8.2
            theNotification.alertTitle = @"Post scheduled";
        }
        theNotification.applicationIconBadgeNumber = 1;
        theNotification.userInfo = [NSDictionary dictionaryWithObject:object.key forKey:@"key"];
        if ([theNotification respondsToSelector:@selector(setCategory:)]) {
            //only ios 8.2
            theNotification.category = @"standard";
        }
        theNotification.soundName = @"TrainStation.wav";
        
        object.postLocalNotification = theNotification;
    
        dispatch_async(dispatch_get_main_queue(), ^{

            saveTimer = [NSTimer scheduledTimerWithTimeInterval:SaveTimerTime target:self selector:@selector(save) userInfo:nil repeats:NO];
            [[UIApplication sharedApplication] scheduleLocalNotification:theNotification];
        });
    });
    
    
    
}

- (void)removePost:(scheduledPostModel *)post withDelete:(BOOL)deleteAlso
{
    [arrayOfPosts removeObject:post];
    NSError *error;
    
    if (deleteAlso) {
        [[NSFileManager defaultManager] removeItemAtPath:post.postImageLocation error:&error];
    }
    
    UILocalNotification *notification = post.postLocalNotification;
    NSArray *notifications = [[UIApplication sharedApplication] scheduledLocalNotifications];
    for (UILocalNotification *aNotification in notifications) {
        NSString *key = [notification.userInfo objectForKey:@"key"];
        if ([key isEqualToString:post.key]) {
            [[UIApplication sharedApplication] cancelLocalNotification:aNotification];
        }
    }
    
    if (saveTimer) {
        [saveTimer invalidate];
    }
    saveTimer = [NSTimer scheduledTimerWithTimeInterval:SaveTimerTime target:self selector:@selector(save) userInfo:nil repeats:NO];
    
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
    NSTimeInterval snoozeTime = 60*(60)+20;  //1 hour and 1 min
    
    scheduledPostModel *newPost = [[scheduledPostModel alloc] init];
    newPost.postCaption = post.postCaption;
    newPost.postImage = post.postImage;     //newPost.postImage = [post.postImage deepCopy];
    if ([post.postTime compare:[NSDate date]] == NSOrderedAscending) {
        //if time is in the past snooze to an hour from now
        newPost.postTime = [NSDate dateWithTimeIntervalSinceNow:snoozeTime];
    } else {
        newPost.postTime = [post.postTime dateByAddingTimeInterval:snoozeTime];
    }
    
    [self removePost:post withDelete:NO];
    [self addPost:newPost];
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
