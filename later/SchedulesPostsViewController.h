//
//  SchedulesPostsViewController.h
//  later
//
//  Created by Adam Juhasz on 4/13/15.
//  Copyright (c) 2015 Adam Juhasz. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SchedulesPostsViewController : UIViewController <UIScrollViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UIDocumentInteractionControllerDelegate, UIGestureRecognizerDelegate>

@property IBOutlet UIScrollView *scheduledScroller;
@property IBOutlet UIView *menuBar;
@property IBOutlet UICollectionView *collectionView;
@property IBOutletCollection(UIView) NSArray *scheduleMenuViews;
@property IBOutletCollection(UIView) NSArray *photoPickerMenuViews;
@property IBOutlet UIView *selectedPostView;
@property IBOutlet UIImageView *SelectedPostImageView;
@property IBOutlet UIView *pullDownHelperView;
@property IBOutlet NSLayoutConstraint *topConstraint;

- (void)popController:(UIViewController*)controller withSuccess:(void (^)(void))success;
- (void)pushController:(UIViewController*)controller withSuccess:(void (^)(void))success;

@end
