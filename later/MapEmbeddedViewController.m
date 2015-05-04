//
//  MapEmbeddedViewController.m
//  later
//
//  Created by Adam Juhasz on 5/1/15.
//  Copyright (c) 2015 Adam Juhasz. All rights reserved.
//

#import "MapEmbeddedViewController.h"
#import <InstagramKit/InstagramKit.h>

@interface MapEmbeddedViewController ()
{
    NSTimer *timeoutTimer;
}
@end

@implementation MapEmbeddedViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)updateLocations
{
    timeoutTimer = nil;
    [[InstagramEngine sharedEngine] searchLocationsAtLocation:self.mapView.centerCoordinate withSuccess:^(NSArray *locations) {
        for (InstagramLocation *loc in locations) {
            NSLog(@"%@", loc.name);
        }
    } failure:nil];
}

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated
{
    [timeoutTimer invalidate];
    timeoutTimer = [NSTimer scheduledTimerWithTimeInterval:0.3 target:self selector:@selector(updateLocations) userInfo:nil repeats:NO];
}
                    
                    

@end
