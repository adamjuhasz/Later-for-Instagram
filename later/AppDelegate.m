//
//  AppDelegate.m
//  later
//
//  Created by Adam Juhasz on 4/13/15.
//  Copyright (c) 2015 Adam Juhasz. All rights reserved.
//

#import "AppDelegate.h"
#import <InstagramKit/InstagramKit.h>
#import "PostDBSingleton.h"
#import <Fabric/Fabric.h>
#import <Crashlytics/Crashlytics.h>
#import <ImageIO/ImageIO.h>
#import "NotificationStrings.h"
#import <Localytics/Localytics.h>
#import <ReactiveCocoa/ReactiveCocoa.h>

@interface AppDelegate ()

@end

@implementation AppDelegate

- (void)setBadge
{
    NSArray *posts = [[PostDBSingleton singleton] allposts];
    NSInteger pastDuePosts = 0;
    for (scheduledPostModel *post in posts) {
        if ([post.postTime compare:[NSDate date]] == NSOrderedAscending) {
            pastDuePosts++;
        }
    }
    
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:pastDuePosts];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    NSBundle* bundle = [NSBundle mainBundle];
    NSString* plistPath = [bundle pathForResource:@"localytics" ofType:@"plist"];
    NSDictionary *localyticsDictionary = [[NSDictionary alloc] initWithContentsOfFile:plistPath];
    
    #ifdef DEBUG
        [Localytics integrate:[localyticsDictionary objectForKey:@"Debug-Key"]];
    #else
        [Fabric with:@[CrashlyticsKit]];
        [Localytics integrate:[localyticsDictionary objectForKey:@"Key"]];
    #endif
    
    [Localytics setCollectAdvertisingIdentifier:NO];
    
    if (application.applicationState != UIApplicationStateBackground)
    {
        [Localytics openSession];
    }
    
    if ([launchOptions objectForKey:UIApplicationLaunchOptionsLocalNotificationKey]) {
        //not called if user selects an action, will call 'handleActionWithIdentifier' with info
        UILocalNotification *swipedNotification = [launchOptions objectForKey:UIApplicationLaunchOptionsLocalNotificationKey];
        self.notificationPostKey = [swipedNotification.userInfo objectForKey:@"key"];
        self.notificationAction = @"view";
        [Localytics tagEvent:@"clickedNotification" attributes:[NSDictionary dictionaryWithObject:@"view" forKey:@"action"]];
    }
    
    NSString *accessToken = [[NSUserDefaults standardUserDefaults] objectForKey:@"instagramAccessToken"];
    if (accessToken) {
        [[InstagramEngine sharedEngine] setAccessToken:accessToken];
    }
    [RACObserve([InstagramEngine sharedEngine], accessToken) subscribeNext:^(NSString *accessToken) {
        if (accessToken == nil) {
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"instagramAccessToken"];
        }
    }];

    [self setBadge];
    return YES;
}

- (void)application:(UIApplication *)application handleActionWithIdentifier:(NSString *)identifier forLocalNotification:(UILocalNotification *)notification completionHandler:(void (^)())completionHandler
{
    if ([identifier isEqualToString:@"snooze"]) {
        scheduledPostModel *post = [[PostDBSingleton singleton] postForKey:[notification.userInfo objectForKey:@"key"]];
        [[PostDBSingleton singleton] snoozePost:post];
    } else {
        scheduledPostModel *post = [[PostDBSingleton singleton] postForKey:[notification.userInfo objectForKey:@"key"]];
        
        self.notificationPostKey = [notification.userInfo objectForKey:@"key"];
        self.notificationAction = identifier;
        
        NSDictionary *userinfo = [NSDictionary dictionaryWithObject:post forKey:@"post"];
        [[NSNotificationCenter defaultCenter] postNotificationName:kPostToBeSentNotification object:nil userInfo:userinfo];
    }
    if (identifier) {
        [Localytics tagEvent:@"clickedNotification" attributes:[NSDictionary dictionaryWithObject:identifier forKey:@"action"]];
    } else {
        [Localytics tagEvent:@"clickedNotification"];
    }
    
    if (completionHandler) {
        completionHandler();
    }
    
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    [Localytics closeSession];
    [Localytics upload];
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    [[PostDBSingleton singleton] save];
    [Localytics closeSession];
    [Localytics upload];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    [self setBadge];
    [Localytics openSession];
    [Localytics upload];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    [Localytics openSession];
    [Localytics upload];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (scheduledPostModel*)openImageUrl:(NSURL*)url withCaption:(NSString*)caption
{
    scheduledPostModel *newPost = nil;
    
    if ([url.pathExtension isEqualToString:@"igo"] || [url.pathExtension isEqualToString:@"ig"]) {
        //instagram file
        newPost = [[scheduledPostModel alloc] init];
        
        CGImageSourceRef imageRef = CGImageSourceCreateWithURL((__bridge CFURLRef)url, NULL);
        NSDictionary *imageProperty = (__bridge NSDictionary*)CGImageSourceCopyPropertiesAtIndex(imageRef, 0, NULL);
        CFStringRef fileDp = CGImageSourceGetType(imageRef);
        CFStringRef fileType = CFCopyDescription(fileDp);
        NSString *typeRef = (__bridge NSString*)fileType;
        if ([typeRef isEqualToString:@"public.jpeg"] == NO) {
            NSLog(@"bad file is %@", typeRef);
        }
        CFRelease(fileType);
        //NSDictionary *exifDictionary = [imageProperty valueForKey:(NSString*)kCGImagePropertyExifDictionary];

        NSDictionary *gpsDictionary = [imageProperty valueForKey:(NSString*)kCGImagePropertyGPSDictionary];
        if ([gpsDictionary objectForKey:(NSString*)kCGImagePropertyGPSLatitude] && [gpsDictionary objectForKey:(NSString*)kCGImagePropertyGPSLongitude]) {
            CLLocationDegrees latitude = [[gpsDictionary objectForKey:(NSString*)kCGImagePropertyGPSLatitude] doubleValue];
            CLLocationDegrees longitude = [[gpsDictionary objectForKey:(NSString*)kCGImagePropertyGPSLongitude] doubleValue];
            if ([[gpsDictionary objectForKey:(NSString*)kCGImagePropertyGPSLatitudeRef] isEqualToString:@"S"]) {
                latitude *= -1;
            }
            if ([[gpsDictionary objectForKey:(NSString*)kCGImagePropertyGPSLongitudeRef] isEqualToString:@"W"]) {
                longitude *= -1;
            }
            CLLocation *newlocation = [[CLLocation alloc] initWithLatitude:latitude longitude:longitude];
            newPost.postLocation = newlocation;
        }
        
        UIImage *inputImage = [UIImage imageWithData:[NSData dataWithContentsOfURL:url]];
        newPost.postImage = inputImage;
        newPost.postCaption = caption;
        newPost.postTime = [NSDate dateWithTimeIntervalSinceNow:60*60];
        if (newPost) {
            [[PostDBSingleton singleton] addPost:newPost];
        }
        
        NSError *error;
        [[NSFileManager defaultManager] removeItemAtURL:url error:&error];
        [Localytics tagEvent:@"importPhotoFromAnotherApp"];
    }
    return newPost;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    if ([[url scheme] isEqualToString:@"file"]) {
        //being asked to open file, app is already open
        if ([url.pathExtension isEqualToString:@"igo"] || [url.pathExtension isEqualToString:@"ig"]) {
            NSString *caption = @"";
            if (annotation) {
                if ([annotation isKindOfClass:[NSDictionary class]]) {
                    NSDictionary *annotationDictionary = (NSDictionary*)annotation;
                    if ([annotationDictionary objectForKey:@"InstagramCaption"]) {
                        caption = [annotationDictionary objectForKey:@"InstagramCaption"];
                    }
                }
            }
            
            //instagram file
            scheduledPostModel *newPost = [self openImageUrl:url withCaption:caption];

            NSDictionary *userInfo = [NSDictionary dictionaryWithObject:newPost forKey:@"post"];
            
            self.notificationPostKey = newPost.key;
            self.notificationAction = @"edit";
            
            //used if
            [[NSNotificationCenter defaultCenter] postNotificationName:@"postToBeEdited" object:nil userInfo:userInfo];

        }
    } else if ([[url scheme] isEqualToString:@"later"]) {
        //coming back from login loop
        BOOL loginSucess = [[InstagramEngine sharedEngine] application:application openURL:url sourceApplication:sourceApplication annotation:annotation];
    
        if (loginSucess) {
            [[NSNotificationCenter defaultCenter] postNotificationName:kLaterInstagramLoginSuccess object:nil];
            [Localytics tagEvent:@"InstagramLoginSuccess"];
        }
        return loginSucess;
    }
    
    return YES;
}

- (void)application:(UIApplication *)app didReceiveLocalNotification:(UILocalNotification *)notif {
    [[NSNotificationCenter defaultCenter] postNotificationName:kLaterShowPostFromLocalNotification object:nil userInfo:notif.userInfo];
}

@end
