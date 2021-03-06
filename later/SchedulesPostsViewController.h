//
//  SchedulesPostsViewController.h
//  later
//
//  Created by Adam Juhasz on 4/13/15.
//  Copyright (c) 2015 Adam Juhasz. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <VBFPopFlatButton/VBFPopFlatButton.h>

@interface SchedulesPostsViewController : UIViewController <UIScrollViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UIDocumentInteractionControllerDelegate, UIGestureRecognizerDelegate>

@property IBOutlet UIScrollView *scheduledScroller;
@property IBOutlet UIView *menuBar;
@property IBOutlet UICollectionView *collectionView;
@property IBOutlet NSLayoutConstraint *topConstraint;
@property IBOutlet VBFPopFlatButton *addButton;
@property IBOutletCollection(UIView) NSArray *gestureInstructions;
@property IBOutlet UIImageView *collectionViewEnlargedImage;

- (void)popController:(UIViewController*)controller withSuccess:(void (^)(void))success;
- (void)pushController:(UIViewController*)controller withSuccess:(void (^)(void))success;

@end
