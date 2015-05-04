//
//  MapEmbeddedViewController.h
//  later
//
//  Created by Adam Juhasz on 5/1/15.
//  Copyright (c) 2015 Adam Juhasz. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

@interface MapEmbeddedViewController : UIViewController <MKMapViewDelegate>

@property IBOutlet MKMapView *mapView;

@end
