//
//  MapEmbeddedViewController.h
//  later
//
//  Created by Adam Juhasz on 5/1/15.
//  Copyright (c) 2015 Adam Juhasz. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

@protocol LocationHolderDelegate <NSObject>
@required
- (void)setLocation:(CLLocation*)location;
- (void)didSelectHashtag:(NSString*)hashtag atIndexPath:(NSIndexPath*)indexPath;
@end

@interface MapEmbeddedViewController : UIViewController <MKMapViewDelegate, UITableViewDataSource, UITableViewDelegate>

@property IBOutlet UIView *resetButton;
@property IBOutlet MKMapView *mapView;
@property IBOutlet UITableView *locationTable;
@property id <LocationHolderDelegate> delegate;
@property CLLocation *initialLocation;

- (IBAction)resetLocation:(id)sender;

@end
