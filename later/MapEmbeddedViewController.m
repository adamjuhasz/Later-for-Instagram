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
    NSMutableArray *foundLocations;
    NSSet *nearbyTags;
    NSInteger protectionTag;
}
@end

@implementation MapEmbeddedViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self.locationTable registerNib:[UINib nibWithNibName:@"HashtagTableViewCell" bundle:nil] forCellReuseIdentifier:@"cell"];
    foundLocations = [NSMutableArray array];
    nearbyTags = [NSSet set];
    protectionTag = 0;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)grabTagsForLocation:(InstagramLocation*)location
{
    if (![[InstagramEngine sharedEngine] accessToken]) {
        return;
    }
    NSInteger protection = protectionTag;
    
    [[InstagramEngine sharedEngine] getMediaAtLocationWithId:location.locationId
                                                 withSuccess:^(NSArray *media, InstagramPaginationInfo *paginationInfo) {
                                                     if (protection != protectionTag) {
                                                         return;
                                                     }
                                                     
                                                     NSCountedSet *countedSetOfTags = [[NSCountedSet alloc] init];
                                                     for (InstagramMedia *specificPost in media) {
                                                         if (specificPost.tags && specificPost.tags.count > 0) {
                                                             for (NSString *tag in specificPost.tags) {
                                                                 [countedSetOfTags addObject:tag];
                                                             }
                                                         }
                                                     }
                                                     
                                                     NSArray *sortedTagsByCount = [countedSetOfTags.allObjects sortedArrayUsingComparator:^(id obj1, id obj2) {
                                                         NSUInteger n = [countedSetOfTags countForObject:obj1];
                                                         NSUInteger m = [countedSetOfTags countForObject:obj2];
                                                         return (n <= m)? (n < m)? NSOrderedDescending : NSOrderedSame : NSOrderedAscending;
                                                     }];
                                                     
                                                     NSInteger index = -1;
                                                     for (int i=0; i<foundLocations.count; i++) {
                                                         if ([foundLocations[i] objectForKey:@"location"] == location) {
                                                             index = i;
                                                             break;
                                                         }
                                                     }
                                                     
                                                     for (int i=0; i<MIN(5,sortedTagsByCount.count); i++) {
                                                         NSInteger tagUsageCount = [countedSetOfTags countForObject:sortedTagsByCount[i]];
                                                         float percentUsingHashtag = (float)tagUsageCount * 100.0 / media.count;
                                                         NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
                                                                               sortedTagsByCount[i], @"hashtag",
                                                                               [NSNumber numberWithInteger:tagUsageCount], @"count",
                                                                               [NSNumber numberWithFloat:percentUsingHashtag], @"percentUsingHashtag",
                                                                               nil];
                                                         [foundLocations insertObject:dict atIndex:index+i+1];
                                                     }
                                                     [self.locationTable reloadData];
                                                 }
                                                     failure:nil];
}

- (void)updateLocations
{
    timeoutTimer = nil;
    protectionTag++;
    NSInteger protection = protectionTag;
    
    CLLocation *location = [[CLLocation alloc] initWithLatitude:self.mapView.centerCoordinate.latitude longitude:self.mapView.centerCoordinate.longitude];
    [self.delegate setLocation:location];
    
    CGFloat spanDistance = MIN(5000, ceil(self.mapView.region.span.latitudeDelta * 111131.745 / 2.0));
    if ([[InstagramEngine sharedEngine] accessToken]) {
        [[InstagramEngine sharedEngine] searchLocationsAtLocation:self.mapView.centerCoordinate distanceInMeters:spanDistance withSuccess:^(NSArray *locations) {
            if (protection != protectionTag) {
                return;
            }
            
            foundLocations = [locations mutableCopy];
            for (int i=0; i<locations.count; i++) {
                NSDictionary *locationDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                                    locations[i], @"location",
                                                    nil];
                [foundLocations replaceObjectAtIndex:i withObject:locationDictionary];
            }
            [self.locationTable reloadData];
            if (foundLocations.count > 0) {
                NSIndexPath *top = [NSIndexPath indexPathForItem:0 inSection:0];
                [self.locationTable scrollToRowAtIndexPath:top atScrollPosition:UITableViewScrollPositionTop animated:YES];
            }
        } failure:nil];
    }
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
    NSDictionary *dict = foundLocations[row];
    if ([dict objectForKey:@"location"]) {
        InstagramLocation *location = [dict objectForKey:@"location"];
        CLLocation *locationForPlace = [[CLLocation alloc] initWithLatitude:location.coordinate.latitude longitude:location.coordinate.longitude];
        CLLocation *mapCenter = [[CLLocation alloc] initWithLatitude:self.mapView.centerCoordinate.latitude longitude:self.mapView.centerCoordinate.longitude];
        NSString *distance = [NSString stringWithFormat:@"%.0f ft", [locationForPlace distanceFromLocation:mapCenter]*3.28084];
        
        cell.tagName.text = location.name;
        cell.tagCount.text = distance;
    } else if ([dict objectForKey:@"hashtag"]) {
        NSString *hashtag = [dict objectForKey:@"hashtag"];
        cell.tagName.text = [NSString stringWithFormat:@"  #%@", hashtag];
        cell.tagCount.text = [NSString stringWithFormat:@"%.0f%% use it", [[dict objectForKey:@"percentUsingHashtag"] floatValue]];
    }

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger row = [indexPath row];
    NSDictionary *dict = foundLocations[row];
    if ([dict objectForKey:@"location"]) {
        InstagramLocation *location = [dict objectForKey:@"location"];
        [self grabTagsForLocation:location];
    } else if ([dict objectForKey:@"hashtag"]) {
        NSString *hashtag = [dict objectForKey:@"hashtag"];
        [self.delegate didSelectHashtag:hashtag atIndexPath:indexPath];
    }
}

@end
