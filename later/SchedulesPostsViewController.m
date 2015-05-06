//
//  SchedulesPostsViewController.m
//  later
//
//  Created by Adam Juhasz on 4/13/15.
//  Copyright (c) 2015 Adam Juhasz. All rights reserved.
//

#import "SchedulesPostsViewController.h"
#import <PhotoManager/PhotoManager.h>
#import "PhotoTableViewCell.h"
#import "CommentEntryViewController.h"
#import "PostDBSingleton.h"
#import "scheduledPostModel.h"
#import "AppDelegate.h"
#import <CoreImage/CoreImage.h>
#import "PostActionsViewController.h"
#import <pop/POP.h>
#import "NotificationStrings.h"
#import <MMTweenAnimation/MMTweenAnimation.h>
#import "PostDisplayView.h"

@interface SchedulesPostsViewController ()
{
    NSMutableArray *viewsInScrollView;
    NSArray *scheduledPosts;
    UIView *addButton;
    UIView *shroud;
    CommentEntryViewController *captionController;
    UIDocumentInteractionController *document;
    scheduledPostModel *postThatIsBeingPosted;
    scheduledPostModel *selectedPost;
    UIView* selectedPostShroud;
    BOOL animating;
    PostDisplayView *postDetailView;
    UIScreenEdgePanGestureRecognizer *leftEdgeGesture, *rightEdgeGesture;
    UIEdgeInsets initialinsets;
}

@property UIDynamicAnimator *animator;
@property UIGravityBehavior *gravityBehavior;

@end

@implementation SchedulesPostsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if ([[PhotoManager sharedManager] authorized] == NO) {

    }
    
    // Do any additional setup after loading the view.
    viewsInScrollView = [NSMutableArray array];
    scheduledPosts = [[PostDBSingleton singleton] allposts];
    
    initialinsets = UIEdgeInsetsMake(64, 0, 0, 0);
    self.scheduledScroller.contentInset = initialinsets;
    self.scheduledScroller.scrollIndicatorInsets = self.scheduledScroller.contentInset;
    
    shroud = [[UIView alloc] initWithFrame:CGRectMake(0, addButton.frame.size.height, self.scheduledScroller.bounds.size.width, self.scheduledScroller.bounds.size.height)];
    shroud.backgroundColor = [UIColor blackColor];
    [self.scheduledScroller addSubview:shroud];
    
    self.collectionView.contentInset = initialinsets;
    self.collectionView.scrollIndicatorInsets = initialinsets;
    //self.collectionView.alpha = 0.0;
    
    [self.collectionView reloadData];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(photosUpdated) name:@"PhotoManagerLoaded" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newPostWasAdded) name:kPostDBUpatedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(editPostNotificatiom:) name:@"postToBeEdited" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notifiedSendPost:) name:kPostToBeSentNotification object:nil];
    
    captionController = [self.storyboard instantiateViewControllerWithIdentifier:@"captionViewController"];
    captionController.delegate = self;
    
    for (UIView *aView in self.scheduleMenuViews) {
        aView.alpha = 1.0;
    }
    for (UIView *aView in self.photoPickerMenuViews) {
        aView.alpha = 0.0;
    }
    
    UIScreenEdgePanGestureRecognizer *leftSideSwipe = [[UIScreenEdgePanGestureRecognizer alloc] initWithTarget:self action:@selector(resetScrollview)];
    leftSideSwipe.edges = UIRectEdgeLeft;
    leftSideSwipe.delaysTouchesBegan = YES;
    [self.view addGestureRecognizer:leftSideSwipe];
    
    self.selectedPostView.layer.cornerRadius = 4;
    self.selectedPostView.clipsToBounds = YES;
    
    UINib *postViewNib = [UINib nibWithNibName:@"PostDisplayView" bundle:nil];
    NSArray *instantiatedViews = [postViewNib instantiateWithOwner:nil options:nil];
    postDetailView = instantiatedViews[0];
    CGRect detailViewFrame = postDetailView.frame;
    postDetailView.hidden = YES;
    [self.view addSubview:postDetailView];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self reloadScrollView];
    
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    if (appDelegate.notificationAction) {
        NSString *postKey = appDelegate.notificationPostKey;
        NSString *action = appDelegate.notificationAction;
        NSLog(@"user wants to %@ a specific notification (%@)", action, postKey);
        
        appDelegate.notificationPostKey = nil;
        appDelegate.notificationAction = nil;
        
        if ([action isEqualToString:@"send"]) {
            [self sendPostToInstragramWithKey:postKey];
        }
        else if ([action isEqualToString:@"edit"]) {
            selectedPost = [[PostDBSingleton singleton] postForKey:postKey];
            [self performSegueWithIdentifier:@"show.editSelectedPost" sender:self];
        }
    }
    
    CGFloat columns = 4;
    UICollectionViewFlowLayout *layout = (id)self.collectionView.collectionViewLayout;
    layout.itemSize = CGSizeMake((self.view.bounds.size.width - (columns-1)*layout.minimumInteritemSpacing - 1 )/columns, (self.view.bounds.size.width - (columns-1)*layout.minimumInteritemSpacing)/columns);
    
    [NSTimer scheduledTimerWithTimeInterval:60 target:self selector:@selector(reloadScrollView) userInfo:nil repeats:YES];
}


- (void)postWasLongTapped:(UIGestureRecognizer*)recognizer
{
    NSLog(@"long tapped");
    scheduledPostModel *thePost = scheduledPosts[recognizer.view.tag];
    [self sendPostToInstragramWithKey:thePost.key];
}

- (void)postWasTapped:(UIGestureRecognizer*)recognizer
{
    NSLog(@"tapped");
    UIView *viewClicked = recognizer.view;
    CGRect frameOfView = [viewClicked convertRect:viewClicked.frame toView:self.view];
    scheduledPostModel *thePost = scheduledPosts[recognizer.view.tag];
    
    selectedPost = thePost;
    [self showSelectedPostWithImage:selectedPost.postImage];
}

- (void)showSelectedPostWithImage:(UIImage*)image
{
    selectedPostShroud = [[UIView alloc] initWithFrame:self.view.bounds];
    selectedPostShroud.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.9];
    selectedPostShroud.alpha = 0.0;
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideSelectedPost)];
    [selectedPostShroud addGestureRecognizer:tap];
    [self.view insertSubview:selectedPostShroud belowSubview:self.selectedPostView];
    
    self.SelectedPostImageView.image = image;
    
    self.selectedPostView.hidden = NO;
    [UIView animateWithDuration:0.4
                          delay:1.0
                        options:0
                     animations:^{
                         selectedPostShroud.alpha = 1.0;
                         self.selectedPostView.alpha = 1.0;
                     }
                     completion:^(BOOL finished) {
                         
                     }];
}

- (void)hideSelectedPost
{
    [UIView animateWithDuration:0.4
                     animations:^{
                         self.selectedPostView.alpha = 0.0;
                         selectedPostShroud.alpha = 0.0;
                     }
                     completion:^(BOOL finished) {
                         self.selectedPostView.hidden = YES;
                         [selectedPostShroud removeFromSuperview];
                         selectedPostShroud = nil;
                     }];
}

- (IBAction)snoozeSelectedPost
{
    [[PostDBSingleton singleton] snoozePost:selectedPost];
    [self hideSelectedPost];
    [self reloadScrollView];
}

- (IBAction)deleteSelectedPost
{
    [[PostDBSingleton singleton] removePost:selectedPost withDelete:YES];
    [self hideSelectedPost];
    [self reloadScrollView];
}

- (IBAction)sendSelectedPostToInstagram
{
    [self sendPostToInstragramWithKey:selectedPost.key];
}

- (void)sendPostToInstragramWithKey:(NSString*)postKey
{
    NSArray *allposts = [[PostDBSingleton singleton] allposts];
    selectedPost = nil;
    for (scheduledPostModel *post in allposts) {
        if ([postKey isEqualToString:post.key]) {
            selectedPost = post;
        }
    }
    
    if (selectedPost  && document == nil) {
        document = [UIDocumentInteractionController interactionControllerWithURL:[NSURL fileURLWithPath:selectedPost.postImageLocation isDirectory:NO]];
        document.UTI = @"com.instagram.exclusivegram";
        document.delegate = self;
        document.annotation = [NSDictionary dictionaryWithObject:selectedPost.postCaption forKey:@"InstagramCaption"];
        
        BOOL success = [document presentOpenInMenuFromRect:CGRectMake(1, 1, 1, 1) inView:self.navigationController.view animated:YES];
        if (success) {
            postThatIsBeingPosted = selectedPost;
        }
    }
}

- (void)documentInteractionControllerDidDismissOpenInMenu:(UIDocumentInteractionController *)controller
{
    document = nil;
}

- (void)documentInteractionController:(UIDocumentInteractionController *)controller didEndSendingToApplication:(NSString *)application
{
    document = nil; //not needed as 'documentInteractionControllerDidDismissOpenInMenu' will be called
    
    [self hideSelectedPost];
    
    [[PostDBSingleton singleton] removePost:postThatIsBeingPosted withDelete:YES];
    postThatIsBeingPosted = nil;
}

- (void)photosUpdated
{
    [self.collectionView reloadData];
}

- (NSAttributedString*)stringForDate:(NSDate*)dateToBe
{
    // Get the system calendar
    NSCalendar *sysCalendar = [NSCalendar currentCalendar];
    
    // Create the NSDates
    NSDate *currentDate = [[NSDate alloc] init];

    // Get conversion to months, days, hours, minutes
    unsigned int unitFlags = NSCalendarUnitSecond |  NSCalendarUnitMinute  | NSCalendarUnitHour | NSCalendarUnitDay | NSCalendarUnitMonth;
    NSDateComponents *breakdownInfo = [sysCalendar components:unitFlags fromDate:currentDate  toDate:dateToBe  options:0];
    //NSLog(@"Break down: %ld sec : %ld min : %ld hours : %ld days : %ld months", [breakdownInfo second], [breakdownInfo minute], [breakdownInfo hour], [breakdownInfo day], [breakdownInfo month]);
    
    UIFont *font = [UIFont fontWithName:@"HelveticaNeue-UltraLight" size:45];
    NSDictionary *attrsDictionary =[NSDictionary dictionaryWithObject:font forKey:NSFontAttributeName];
    UIFont *smallFont = [UIFont fontWithName:@"HelveticaNeue-UltraLight" size:30];
    NSDictionary *smallAttrsDictionary =[NSDictionary dictionaryWithObject:smallFont forKey:NSFontAttributeName];
    
    NSMutableAttributedString *timelabelText = [[NSMutableAttributedString alloc] initWithString:@"Soon" attributes:attrsDictionary];
    if (ABS(breakdownInfo.month) > 0) {
        timelabelText = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%ld", (long)ABS(breakdownInfo.month)] attributes:attrsDictionary];
        [timelabelText appendAttributedString:[[NSAttributedString alloc] initWithString:@"mo" attributes:smallAttrsDictionary]];
    } else if (ABS(breakdownInfo.day) > 0) {
        timelabelText = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%ld", (long)ABS(breakdownInfo.day)] attributes:attrsDictionary];
        [timelabelText appendAttributedString:[[NSAttributedString alloc] initWithString:@"d" attributes:smallAttrsDictionary]];
    } else if (ABS(breakdownInfo.hour) > 0) {
        timelabelText = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%ld", (long)ABS(breakdownInfo.hour)] attributes:attrsDictionary];
        [timelabelText appendAttributedString:[[NSAttributedString alloc] initWithString:@"h" attributes:smallAttrsDictionary]];
    } else if (ABS(breakdownInfo.minute) > 0) {
        timelabelText = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%ld", (long)ABS(breakdownInfo.minute)] attributes:attrsDictionary];
        [timelabelText appendAttributedString:[[NSAttributedString alloc] initWithString:@"m" attributes:smallAttrsDictionary]];
    }
    
    if ([dateToBe compare:currentDate] == NSOrderedDescending) {
        
    } else {
        if ([timelabelText.string isEqualToString:@"Soon"]) {
            timelabelText = [[NSMutableAttributedString alloc] initWithString:@"Now" attributes:attrsDictionary] ;
        } else {
            [timelabelText appendAttributedString:[[NSAttributedString alloc] initWithString:@" late" attributes:smallAttrsDictionary]];
        }
    }

    return timelabelText;
}

- (void)reloadScrollView
{
    scheduledPosts = [[PostDBSingleton singleton] allposts];
    
    if (scheduledPosts.count == 0) {
        self.pullDownHelperView.hidden = NO;
    } else {
        self.pullDownHelperView.hidden = YES;
    }
    
    for (UIView *subview in viewsInScrollView) {
        [subview removeFromSuperview];
    }
    [viewsInScrollView removeAllObjects];
    
    CGFloat border = 4;
    CGFloat columns = 2;
    CGFloat width = (self.scheduledScroller.bounds.size.width - border)/columns;
    CGRect mainRect = CGRectMake(0, border, width, width);
    CGRect currrentFrame = CGRectZero;
    for (int i=0; i<scheduledPosts.count; i++) {
        int column = i % 2;
        int row = floor(i / 2.0);
        
        scheduledPostModel *post = scheduledPosts[i];
        
        currrentFrame = CGRectOffset(mainRect, column*(mainRect.size.width+border), row*(mainRect.size.height+border));
        UIView *newImage =  [[UIView alloc] initWithFrame:currrentFrame];
        newImage.backgroundColor = [UIColor darkGrayColor];
        //newImage.layer.cornerRadius = 10.0;
        newImage.clipsToBounds = YES;
        
        CGRect imageRect = CGRectMake(0, 0, currrentFrame.size.width, currrentFrame.size.width);
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:imageRect];
        imageView.image = post.postImage;
        imageView.contentMode = UIViewContentModeScaleAspectFill;
        imageView.clipsToBounds = YES;
        [newImage addSubview:imageView];
        
        CAGradientLayer *gradient = [CAGradientLayer layer];
        id colorTop = (id)[[UIColor clearColor] CGColor];
        id colorBottom = (id)[[UIColor colorWithWhite:0.0 alpha:0.9] CGColor];
        gradient.colors = @[colorTop, colorBottom];
        NSNumber *stopTop = [NSNumber numberWithFloat:0.2];
        NSNumber *stopBottom = [NSNumber numberWithFloat:0.9];
        gradient.locations = @[stopTop, stopBottom];
        gradient.frame = newImage.bounds;
        [newImage.layer insertSublayer:gradient above:imageView.layer];
        
        CGRect timeLabelRect = CGRectMake(5, mainRect.size.height - (40+5), imageRect.size.width - 5, 40);
        UILabel *timeLabel = [[UILabel alloc] initWithFrame:timeLabelRect];
        timeLabel.textColor = [UIColor whiteColor];
        timeLabel.attributedText = [self stringForDate:post.postTime];
        timeLabel.font = [UIFont fontWithName:@"HelveticaNeue-UltraLight" size:45];
        [newImage addSubview:timeLabel];
        
        newImage.tag = i;
        UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(postWasLongTapped:)];
        [newImage addGestureRecognizer:longPress];
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(postWasTapped:)];
        [newImage addGestureRecognizer:tap];
        
        
        [self.scheduledScroller insertSubview:newImage aboveSubview:shroud];
        [viewsInScrollView addObject:newImage];
    }
    
    self.scheduledScroller.contentSize = CGSizeMake(self.scheduledScroller.bounds.size.width,
                                                    MAX(currrentFrame.origin.y + currrentFrame.size.height,
                                                        0));
    shroud.frame = CGRectMake(0, 0, self.scheduledScroller.contentSize.width, self.scheduledScroller.contentSize.height + self.scheduledScroller.bounds.size.height);
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (scrollView != self.scheduledScroller) {
        return;
    }
    
    if (scrollView.contentOffset.y < -1 * scrollView.contentInset.top && animating == NO) {
        CGFloat expansionSpace = scrollView.contentOffset.y - scrollView.contentInset.top*-1;
        CGFloat maxDragDown = 250;
        
        CGFloat alphaPercent = ABS(expansionSpace/maxDragDown);
        CGFloat scale = MIN(1.0,alphaPercent*0.1+0.95);
        self.collectionView.transform = CGAffineTransformMakeScale(scale, scale);
        self.collectionView.alpha = MAX(0.5,alphaPercent);
        //NSLog(@"alphaPercent: %f", alphaPercent);
    }
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset
{
    if (scrollView != self.scheduledScroller) {
        return;
    }
    
    if ((velocity.y < -1.0 && scrollView.contentOffset.y < -100) || (scrollView.contentOffset.y < -150)) {
        *targetContentOffset = CGPointZero;
        self.topConstraint.constant = scrollView.contentOffset.y;
        [self.scheduledScroller layoutIfNeeded];
        [self hideScrollviewWithVelocity:velocity.y];
    }
}

- (void)authorizePhotos
{
    if ([[PhotoManager sharedManager] authorized] == NO) {
        [[PhotoManager sharedManager] getAlbumNamesWhenDone:^{
            NSLog(@"%@", [[PhotoManager sharedManager] albumNames]);
            NSLog(@"Camera Roll: %@", [[PhotoManager sharedManager] cameraRollAlbumName]);
            NSRange cacheRange = {0, 50};
            [[PhotoManager sharedManager] cacheThumbnailsForAlbum:[[PhotoManager sharedManager] cameraRollAlbumName]
                                                         withRange:cacheRange
                                                   completionBlock:^(NSDictionary *photos) {
                                                       //NSLog(@"%@", photos);
                                                       dispatch_async(dispatch_get_main_queue(), ^{
                                                           [self.collectionView reloadData];
                                                       });
                                                   }];
        }];
    }
}

- (IBAction)hideScrollview
{
    [self hideScrollviewWithVelocity:0];
}

- (void)hideScrollviewWithVelocity:(CGFloat)velocity
{
    animating = YES;
    
    [self authorizePhotos];
    
    self.scheduledScroller.layer.cornerRadius = 20.0;
    self.scheduledScroller.clipsToBounds = YES;
    
    CGRect goneFrame = self.scheduledScroller.frame;
    goneFrame.origin.y = self.view.bounds.size.height;
    
    //---- Scroll View ---
    POPSpringAnimation *scheduldPostVerticalanimation = [POPSpringAnimation animationWithPropertyNamed:kPOPLayoutConstraintConstant];
    scheduldPostVerticalanimation.springBounciness = 8;
    scheduldPostVerticalanimation.velocity = @(velocity);
    //scheduldPostVerticalanimation.fromValue =
    scheduldPostVerticalanimation.toValue = @(self.view.bounds.size.height - (100)); //64 for nav bar and position uses center point
    scheduldPostVerticalanimation.completionBlock = ^(POPAnimation *anim, BOOL finished){
        };
    [self.topConstraint pop_addAnimation:scheduldPostVerticalanimation forKey:@"dropDown"];
    
    POPSpringAnimation *scheduledPostInset = [POPSpringAnimation animationWithPropertyNamed:kPOPScrollViewContentInset];
    scheduledPostInset.toValue = [NSValue valueWithUIEdgeInsets:UIEdgeInsetsMake(0, 0, 0, 0)];
    scheduledPostInset.springBounciness = scheduldPostVerticalanimation.springBounciness;
    scheduledPostInset.velocity = [NSValue valueWithUIEdgeInsets:UIEdgeInsetsMake(velocity, 0, 0, 0)];
    [self.scheduledScroller pop_addAnimation:scheduledPostInset forKey:@"inset"];
    
    POPSpringAnimation *scheduledPostOffset = [POPSpringAnimation animationWithPropertyNamed:kPOPScrollViewContentOffset];
    scheduledPostOffset.toValue = [NSValue valueWithCGPoint:CGPointMake(0, -2)];
    scheduledPostOffset.springBounciness = scheduldPostVerticalanimation.springBounciness;
    scheduledPostOffset.velocity = [NSValue valueWithCGPoint:CGPointMake(0, velocity)];
    [self.scheduledScroller pop_addAnimation:scheduledPostOffset forKey:@"offset"];
    
    POPSpringAnimation *sch
    
    //---- Collection View ----
    POPSpringAnimation *offset = [POPSpringAnimation animationWithPropertyNamed:kPOPScrollViewContentOffset];
    offset.toValue = [NSValue valueWithCGPoint:CGPointMake(0, (self.collectionView.contentInset.top+1)*-1)];
    offset.springBounciness = scheduldPostVerticalanimation.springBounciness;
    offset.velocity = [NSValue valueWithCGPoint:CGPointMake(0, velocity)];
    [self.collectionView pop_addAnimation:offset forKey:@"offset"];
    
    POPSpringAnimation *inset = [POPSpringAnimation animationWithPropertyNamed:kPOPScrollViewContentInset];
    inset.toValue = [NSValue valueWithUIEdgeInsets:UIEdgeInsetsMake(65, 0, 0, 0)];
    inset.springBounciness = scheduldPostVerticalanimation.springBounciness;
    inset.velocity = [NSValue valueWithUIEdgeInsets:UIEdgeInsetsMake(velocity, 0, 0, 0)];
    [self.collectionView pop_addAnimation:inset forKey:@"inset"];
    
    POPSpringAnimation *collectionAlphaAnimation = [POPSpringAnimation animationWithPropertyNamed:kPOPViewAlpha];
    collectionAlphaAnimation.toValue = @(1.0);
    [self.collectionView pop_addAnimation:collectionAlphaAnimation forKey:@"alpha"];
    
    CABasicAnimation *transformAnimation = [CABasicAnimation animationWithKeyPath:@"transform"];
    transformAnimation.duration = 0.2;
    transformAnimation.toValue = [NSValue valueWithCGAffineTransform:CGAffineTransformIdentity];
    [self.collectionView.layer addAnimation:transformAnimation forKey:@"transform"];
    
    [UIView animateWithDuration:0.2
                          delay:0.0
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         for (UIView *aView in self.scheduleMenuViews) {
                             aView.alpha = 0.0;
                         }
                         for (UIView *aView in self.photoPickerMenuViews) {
                             aView.alpha = 1.0;
                         }
                     }
                     completion:nil];
}

- (IBAction)resetScrollview
{
    self.scheduledScroller.userInteractionEnabled = YES;
    self.scheduledScroller.hidden = NO;
    
    CGRect goneFrame = self.scheduledScroller.frame;
    goneFrame.origin.y = 0;
    
    MMTweenAnimation *bounceAnimation = [MMTweenAnimation animation];
    bounceAnimation.functionType = MMTweenFunctionBounce;
    bounceAnimation.easingType = MMTweenEasingOut;
    bounceAnimation.fromValue = self.topConstraint.constant;
    bounceAnimation.toValue = -20;
    bounceAnimation.duration = 0.4;
    bounceAnimation.animationBlock = ^(double currentTime, double duration, double value, id target, MMTweenAnimation *animation){
        NSLayoutConstraint *constraint = (NSLayoutConstraint*)target;
        constraint.constant = value;
        };
    bounceAnimation.completionBlock =  ^(POPAnimation *anim, BOOL finished){
        self.topConstraint.constant = -20;
        };
    [self.topConstraint pop_addAnimation:bounceAnimation forKey:@"top_constraint"];
    
    POPBasicAnimation *scheduledContentOffsetAnimation = [POPBasicAnimation animationWithPropertyNamed:kPOPScrollViewContentOffset];
    scheduledContentOffsetAnimation.toValue = [NSValue valueWithCGPoint:CGPointMake(0, -64)];
    [self.scheduledScroller pop_addAnimation:scheduledContentOffsetAnimation forKey:@"contentOffset"];
    
    POPSpringAnimation *scheduledPostInsetAnimation = [POPSpringAnimation animationWithPropertyNamed:kPOPScrollViewContentInset];
    scheduledPostInsetAnimation.toValue = [NSValue valueWithUIEdgeInsets:initialinsets];
    scheduledPostInsetAnimation.springBounciness = 8.0;
    [self.scheduledScroller pop_addAnimation:scheduledPostInsetAnimation forKey:@"inset"];
    
    [UIView animateWithDuration:0.4
                          delay:0.0
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         self.collectionView.alpha = 0.0;
                         self.collectionView.contentInset = self.scheduledScroller.contentInset;
                         self.collectionView.scrollIndicatorInsets = self.scheduledScroller.contentInset;
                         self.collectionView.contentOffset = CGPointZero;
                         
                         for (UIView *aView in self.scheduleMenuViews) {
                             aView.alpha = 1.0;
                         }
                         for (UIView *aView in self.photoPickerMenuViews) {
                             aView.alpha = 0.0;
                         }
                     }
                     completion:^(BOOL finished) {
                         self.collectionView.transform = CGAffineTransformIdentity;
                         animating = NO;
                         //self.scheduledScroller.frame = goneFrame;
                     }];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    PhotoManager *shared = [PhotoManager sharedManager];
    NSInteger count = [shared countForAlbum:shared.cameraRollAlbumName];
    if (count <= 0) {
        return 30;
    }
    return count;
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    PhotoTableViewCell *myCell = [collectionView
                           dequeueReusableCellWithReuseIdentifier:@"PhotoCell"
                           forIndexPath:indexPath];
    
    long row = [indexPath row];
    
    PhotoManager *shared =  [PhotoManager sharedManager];
    if (shared.authorized) {
        [shared getThumbnailFor:shared.cameraRollAlbumName atIndex:row completionBlock:^(UIImage *image) {
            myCell.photoView.image = image;
        }];
    }
    
    return myCell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    captionController.comments.text = @"";
    captionController.post = nil;
    [captionController resetView];
    
    [[PhotoManager sharedManager] getThumbnailFor:[[PhotoManager sharedManager] cameraRollAlbumName]
                                          atIndex:indexPath.row
                                  completionBlock:^(UIImage *image) {
                                      [captionController setThumbnail:image];
                                  }];
    
    [self pushController:captionController
             withSuccess:^{
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [[PhotoManager sharedManager] fullsizeImageIn:[[PhotoManager sharedManager] cameraRollAlbumName]
                                                  atIndex:indexPath.row
                                          completionBlock:^(UIImage *image, CLLocation *location) {
                                              [captionController setPhoto:image];
                                              captionController.location = location;
                                          }];
            
        });
    }];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        otherGestureRecognizer.enabled = NO;
        otherGestureRecognizer.enabled = YES;
    }
    return YES;
}

- (void)edgeSwipe:(UIScreenEdgePanGestureRecognizer*)recognizer
{
    CGFloat xTranslation = [recognizer translationInView:self.view].x;
    CGFloat xVelocity = [recognizer velocityInView:self.view].x;
    
    POPBasicAnimation *animation = [POPBasicAnimation animationWithPropertyNamed:kPOPViewFrame];
    BOOL edgeSwipeSameDirection = NO;
    switch (recognizer.state) {
        case UIGestureRecognizerStateBegan:
            [self.view endEditing:YES];
            captionController.view.frame = CGRectMake(xTranslation, 0, captionController.view.frame.size.width, captionController.view.frame.size.height);
            break;
            
        case UIGestureRecognizerStateEnded:
            if (xTranslation > 0 && xVelocity > 0 && recognizer == leftEdgeGesture) {
                edgeSwipeSameDirection = YES;
            }
            if (xTranslation < 0 && xVelocity < 0 && recognizer == rightEdgeGesture) {
                edgeSwipeSameDirection = YES;
                [captionController schedulePost];
            }
            if ((ABS(xTranslation) > self.view.frame.size.width/2.0 || ABS(xVelocity) > 50 ) && edgeSwipeSameDirection)  {
                if (xTranslation > 0) {
                    animation.toValue = [NSValue valueWithCGRect:CGRectMake(captionController.view.frame.size.width, 0, captionController.view.frame.size.width, captionController.view.frame.size.height)];
                } else {
                    animation.toValue = [NSValue valueWithCGRect:CGRectMake(-1*captionController.view.frame.size.width, 0, captionController.view.frame.size.width, captionController.view.frame.size.height)];
                }
                animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
                animation.completionBlock = ^(POPAnimation *anim, BOOL finished) {
                    [self removeController:captionController];
                };
            } else {
                animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
                animation.toValue = [NSValue valueWithCGRect:CGRectMake(0, 0, captionController.view.frame.size.width, captionController.view.frame.size.height)];
            }
            [captionController.view pop_addAnimation:animation forKey:@"slide"];
            break;
                                            
        default:
            captionController.view.frame = CGRectMake(xTranslation, 0, captionController.view.frame.size.width, captionController.view.frame.size.height);
            break;
    }
}

- (void)pushController:(UIViewController*)controller withSuccess:(void (^)(void))success
{
    CGRect initialFrame = CGRectMake(self.view.bounds.size.width, 0, self.view.bounds.size.width, self.view.bounds.size.height);
    controller.view.frame = initialFrame;
    
    [self addChildViewController:controller];
    [self.view addSubview:controller.view];
    
    POPBasicAnimation *animation = [POPBasicAnimation animationWithPropertyNamed:kPOPViewFrame];
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
    animation.fromValue = [NSValue valueWithCGRect:initialFrame];
    animation.duration = 0.4;
    animation.toValue = [NSValue valueWithCGRect:self.view.bounds];
    animation.completionBlock = ^(POPAnimation *anim, BOOL finished) {
        [captionController didMoveToParentViewController:self];
        if(success) {
            success();
        }
    };
    
    leftEdgeGesture = [[UIScreenEdgePanGestureRecognizer alloc] initWithTarget:self action:@selector(edgeSwipe:)];
    leftEdgeGesture.edges = UIRectEdgeLeft;
    leftEdgeGesture.delaysTouchesBegan = YES;
    leftEdgeGesture.delegate = self;
    [self.view addGestureRecognizer:leftEdgeGesture];
    
    rightEdgeGesture = [[UIScreenEdgePanGestureRecognizer alloc] initWithTarget:self action:@selector(edgeSwipe:)];
    rightEdgeGesture.edges = UIRectEdgeRight;
    rightEdgeGesture.delaysTouchesBegan = YES;
    rightEdgeGesture.delegate = self;
    [self.view addGestureRecognizer:rightEdgeGesture];
    
    [controller.view pop_addAnimation:animation forKey:@"frame"];
}

- (void)popController:(UIViewController *)controller withDirection:(UIRectEdge)direction withSuccess:(void (^)(void))success
{
    NSInteger index = [self.childViewControllers indexOfObjectIdenticalTo:controller];
    if (index == NSNotFound) {
        if (success)
            success();
        return;
    }
    
    CGRect exitFrame = CGRectMake(self.view.bounds.size.width, 0, self.view.bounds.size.width, self.view.bounds.size.height);
    
    switch (direction) {
        case UIRectEdgeLeft:
            exitFrame = CGRectMake(-1*self.view.bounds.size.width, 0, self.view.bounds.size.width, self.view.bounds.size.height);
            break;
            
        default:
            break;
    }
    
    POPBasicAnimation *animation = [POPBasicAnimation animationWithPropertyNamed:kPOPViewFrame];
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    animation.duration = 0.4;
    animation.toValue = [NSValue valueWithCGRect:exitFrame];
    animation.completionBlock = ^(POPAnimation *anim, BOOL finished) {
        [self removeController:controller];
        if(success) {
            success();
        }
    };
    
    [self.view endEditing:YES];
    [controller.view pop_addAnimation:animation forKey:@"frame_out"];
}

- (void)popController:(UIViewController*)controller withSuccess:(void (^)(void))success
{
    [self popController:controller withDirection:UIRectEdgeRight withSuccess:success];
}

- (void)removeController:(UIViewController*)controller
{
    [controller willMoveToParentViewController:nil];
    [controller.view removeFromSuperview];
    [controller removeFromParentViewController];
    
    [self.view removeGestureRecognizer:leftEdgeGesture];
    [self.view removeGestureRecognizer:rightEdgeGesture];
}

- (void)newPostWasAdded
{
    [self reloadScrollView];
    [self resetScrollview];
    [self popController:captionController withDirection:UIRectEdgeLeft withSuccess:nil];
}

- (void)editPostNotificatiom:(NSNotification*)notification
{
    NSDictionary *userInfo = notification.userInfo;
    scheduledPostModel *post = [userInfo objectForKey:@"post"];
    selectedPost = post;
    
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    appDelegate.notificationPostKey = nil;
    appDelegate.notificationAction = nil;
    
    captionController.post = selectedPost;
    [self pushController:captionController withSuccess:nil];
    [self hideSelectedPost];
}

- (void)notifiedSendPost:(NSNotification*)notification
{
    NSDictionary *userInfo = notification.userInfo;
    scheduledPostModel *post = [userInfo objectForKey:@"post"];
    selectedPost = post;
    
    [self sendSelectedPostToInstagram];
}

@end
