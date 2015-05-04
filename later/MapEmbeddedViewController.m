//
//  MapEmbeddedViewController.m
//  later
//
//  Created by Adam Juhasz on 5/1/15.
//  Copyright (c) 2015 Adam Juhasz. All rights reserved.
//

#import "MapEmbeddedViewController.h"
#import <InstagramKit/InstagramKit.h>
#import "HashtagTableViewCell.h"

@interface MapEmbeddedViewController ()
{
    NSTimer *timeoutTimer;
    NSArray *foundLocations;
    NSSet *nearbyTags;
}
@end

@implementation MapEmbeddedViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self.locationTable registerNib:[UINib nibWithNibName:@"HashtagTableViewCell" bundle:nil] forCellReuseIdentifier:@"cell"];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)updateLocations
{
    timeoutTimer = nil;
    CGFloat spanDistance = MIN(5000, ceil(self.mapView.region.span.latitudeDelta * 111131.745 / 2.0));
    [[InstagramEngine sharedEngine] searchLocationsAtLocation:self.mapView.centerCoordinate distanceInMeters:spanDistance withSuccess:^(NSArray *locations) {
        foundLocations = [locations copy];
        [self.locationTable reloadData];
        if (foundLocations.count > 0) {
            NSIndexPath *top = [NSIndexPath indexPathForItem:0 inSection:0];
            [self.locationTable scrollToRowAtIndexPath:top atScrollPosition:UITableViewScrollPositionTop animated:YES];
        }
        for (int i=0; i<MIN(10, foundLocations.count); i++) {
            InstagramLocation *loc = foundLocations[i];
            [[InstagramEngine sharedEngine] getMediaAtLocationWithId:loc.locationId
                                                         withSuccess:^(NSArray *media, InstagramPaginationInfo *paginationInfo) {
                                                             NSLog(@"%@", media);
                                                         }
                                                             failure:nil];
        }
    } failure:nil];
}

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated
{
    [timeoutTimer invalidate];
    timeoutTimer = [NSTimer scheduledTimerWithTimeInterval:0.3 target:self selector:@selector(updateLocations) userInfo:nil repeats:NO];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return foundLocations.count;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    HashtagTableViewCell *cell = (HashtagTableViewCell*)[tableView dequeueReusableCellWithIdentifier:@"cell"];
    
    NSInteger row = [indexPath row];
    InstagramLocation *location = foundLocations[row];
    
    CLLocation *locationForPlace = [[CLLocation alloc] initWithLatitude:location.coordinate.latitude longitude:location.coordinate.longitude];
    CLLocation *mapCenter = [[CLLocation alloc] initWithLatitude:self.mapView.centerCoordinate.latitude longitude:self.mapView.centerCoordinate.longitude];
    NSString *distance = [NSString stringWithFormat:@"%.0f ft", [locationForPlace distanceFromLocation:mapCenter]*3.28084];
    
    cell.tagName.text = location.name;
    cell.tagCount.text = distance;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger row = [indexPath row];
    InstagramLocation *location = foundLocations[row];
    [self.mapView setCenterCoordinate:location.coordinate animated:YES];
}

@end
