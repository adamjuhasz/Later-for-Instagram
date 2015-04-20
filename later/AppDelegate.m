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


@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    [Fabric with:@[CrashlyticsKit]];

    if ([launchOptions objectForKey:UIApplicationLaunchOptionsLocalNotificationKey]) {
        //not called if user selects an action, will call 'handleActionWithIdentifier' with info
        UILocalNotification *swipedNotification = [launchOptions objectForKey:UIApplicationLaunchOptionsLocalNotificationKey];
        self.notification = swipedNotification;
        self.notificationAction = @"view";
    }
    
    NSArray *posts = [[PostDBSingleton singleton] allposts];
    NSInteger pastDuePosts = 0;
    for (scheduledPostModel *post in posts) {
        if ([post.postTime compare:[NSDate date]] == NSOrderedAscending) {
            pastDuePosts++;
        }
    }
    application.applicationIconBadgeNumber = pastDuePosts;
    
    return YES;
}

- (void)application:(UIApplication *)application handleActionWithIdentifier:(NSString *)identifier forLocalNotification:(UILocalNotification *)notification completionHandler:(void (^)())completionHandler
{
    if ([identifier isEqualToString:@"snooze"]) {
        scheduledPostModel *post = [[PostDBSingleton singleton] postForKey:[notification.userInfo objectForKey:@"key"]];
        [[PostDBSingleton singleton] snoozePost:post];
    } else {
        self.notification = notification;
        self.notificationAction = identifier;
        [[NSNotificationCenter defaultCenter] postNotificationName:@"notificationActedUpod" object:nil];
    }
    
    if (completionHandler) {
        completionHandler();
    }
    
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    BOOL loginSucess = [[InstagramEngine sharedEngine] application:application openURL:url sourceApplication:sourceApplication annotation:annotation];
    
    if (loginSucess) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"InstagramLoginSuccess" object:nil];
    }
    
    return loginSucess;
}

@end
