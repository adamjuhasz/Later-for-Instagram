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
#import <pop/POP.h>
#import "NotificationStrings.h"
#import <MMTweenAnimation/MMTweenAnimation.h>
#import "PostDisplayView.h"
#import <ReactiveCocoa/ReactiveCocoa.h>
#import <Localytics/Localytics.h>
#import <CoreText/CoreText.h>
#import "NSTimer+Blocks.h"
#import "ScheduledPostImageView.h"

#define DEGREES_TO_RADIANS(angle) ((angle) / 180.0 * M_PI)

@interface SchedulesPostsViewController ()
{
    NSMutableArray *viewsInScrollView;
    NSArray *scheduledPosts;
    UIView *shroud;
    CommentEntryViewController *captionController;
    UIDocumentInteractionController *document;
    scheduledPostModel *postThatIsBeingPosted;
    scheduledPostModel *selectedPost;
    UIView* selectedPostShroud;
    UIView* pushedControllerShroud;
    UIView *minimizedSchedulePostPanView;
    PostDisplayView *postDetailView;
    UIScreenEdgePanGestureRecognizer *leftEdgeGesture, *rightEdgeGesture;
    UIEdgeInsets initialinsets;
    CGFloat topLayoutConstantMin;
    CGFloat topLayoutConstantMax;
    CGRect returnImageRect;
    BOOL scrollViewUp;
    UIView *viewSelected;
    UIPanGestureRecognizer *panRecognizerForMinimzedScrollView;
    UITapGestureRecognizer *tapRecognizerForMinimizedScrollView;
    BOOL firstScheduledPostLoad;
}

@property UIDynamicAnimator *animator;
@property UIGravityBehavior *gravityBehavior;

@end

@implementation SchedulesPostsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    viewsInScrollView = [NSMutableArray array];
    scheduledPosts = [NSArray array];
    firstScheduledPostLoad = YES;
    
    if (scheduledPosts.count > 0) {
        for (UIView *view in self.gestureInstructions) {
            view.hidden = YES;
        }
    }
    
    initialinsets = UIEdgeInsetsMake(20, 0, 70, 0);
    self.scheduledScroller.contentInset = initialinsets;
    self.scheduledScroller.scrollIndicatorInsets = UIEdgeInsetsMake(20, 0, 0, 0);;
    self.scheduledScroller.clipsToBounds = YES;
    scrollViewUp = YES;
    
    shroud = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.scheduledScroller.bounds.size.width, self.scheduledScroller.bounds.size.height)];
    shroud.backgroundColor = [UIColor blackColor];
    [self.scheduledScroller addSubview:shroud];
    
    self.collectionView.contentInset = initialinsets;
    self.collectionView.scrollIndicatorInsets = initialinsets;
    //self.collectionView.alpha = 0.0;
    
    [self.collectionView reloadData];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(photosUpdated) name:@"PhotoManagerLoaded" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newPostWasAdded:) name:kPostDBUpatedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(editPostNotificatiom:) name:@"postToBeEdited" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notifiedSendPost:) name:kPostToBeSentNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notifiedShowPost:) name:kLaterShowPostFromLocalNotification object:nil];
    
    captionController = [self.storyboard instantiateViewControllerWithIdentifier:@"captionViewController"];
    captionController.delegate = self;
    
    UINib *postViewNib = [UINib nibWithNibName:@"PostDisplayView" bundle:nil];
    NSArray *instantiatedViews = [postViewNib instantiateWithOwner:nil options:nil];
    postDetailView = instantiatedViews[0];
    postDetailView.hidden = YES;

    [postDetailView.editButton addTarget:self action:@selector(editSelectedPost) forControlEvents:UIControlEventTouchUpInside];
    [postDetailView.snoozeButton addTarget:self action:@selector(snoozeSelectedPost) forControlEvents:UIControlEventTouchUpInside];
    [postDetailView.deleteButton addTarget:self action:@selector(deleteSelectedPost) forControlEvents:UIControlEventTouchUpInside];
    [postDetailView.sendButton addTarget:self action:@selector(sendSelectedPostToInstagram) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view insertSubview:postDetailView aboveSubview:self.menuBar];
    
    postDetailView.frame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.width);
    postDetailView.image.frame = CGRectMake(0, 0, postDetailView.frame.size.width, postDetailView.frame.size.width);
    postDetailView.blurView.frame = postDetailView.image.frame;
    postDetailView.buttonHolderView.center = postDetailView.image.center;
    
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressOnPhotoLibrary:)];
    longPress.allowableMovement = 4000;
    [self.collectionView addGestureRecognizer:longPress];
    
    self.addButton.currentButtonStyle = buttonRoundedStyle;
    self.addButton.roundBackgroundColor = [UIColor colorWithRed:99/255.0 green:173/255.0 blue:255/255.0 alpha:1.0];
    
    minimizedSchedulePostPanView = [[UIView alloc] initWithFrame:self.view.bounds];
    [self.view insertSubview:minimizedSchedulePostPanView aboveSubview:self.scheduledScroller];
    minimizedSchedulePostPanView.userInteractionEnabled = NO;
    
    panRecognizerForMinimzedScrollView = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panScroll:)];
    [minimizedSchedulePostPanView addGestureRecognizer:panRecognizerForMinimzedScrollView];
    
    tapRecognizerForMinimizedScrollView = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showScrollview)];
    [minimizedSchedulePostPanView addGestureRecognizer:tapRecognizerForMinimizedScrollView];
    
    /*[RACObserve(self.topConstraint, constant) subscribeNext:^(NSNumber *number) {
        CGRect frame = minimizedSchedulePostPanView.frame;
        frame.origin.y = [number floatValue];
        minimizedSchedulePostPanView.frame = frame;
    }];*/
}
     
- (CGAffineTransform)transformForAddButtonWithPercent:(CGFloat)percent
{
    CGAffineTransform transformer = CGAffineTransformIdentity;
    transformer = CGAffineTransformTranslate(transformer, -1 * (self.view.frame.size.width - self.addButton.frame.size.width/2.0 - 8) * percent, 0);
    transformer = CGAffineTransformRotate(transformer, DEGREES_TO_RADIANS(-45*percent));
    return transformer;
}

- (void)longPressOnPhotoLibrary:(UILongPressGestureRecognizer*)recognizer
{
    static CGRect frameInMasterView;
    static NSTimer *fullResolutionTimer;
    UICollectionView *collectionView = (UICollectionView*)recognizer.view;
    CGPoint pointOfFinger = [recognizer locationInView:recognizer.view];
    NSIndexPath *indexPath = [collectionView indexPathForItemAtPoint:pointOfFinger];
    if (indexPath != nil) {
        UIView *cell = [collectionView cellForItemAtIndexPath:indexPath];
        frameInMasterView = [self.view convertRect:cell.frame fromView:collectionView];
        NSInteger index = [indexPath indexAtPosition:1];
        [[PhotoManager sharedManager] getThumbnailFor:[[PhotoManager sharedManager] cameraRollAlbumName] atIndex:index completionBlock:^(UIImage *image) {
            if (self.collectionViewEnlargedImage.hidden == YES) {
                POPSpringAnimation *frameAnimation = [POPSpringAnimation animationWithPropertyNamed:kPOPViewFrame];
                frameAnimation.fromValue = [NSValue valueWithCGRect:frameInMasterView];
                CGRect centeredFrame;
                centeredFrame.size = CGSizeMake(CGRectGetWidth(self.view.frame), CGRectGetWidth(self.view.frame));
                centeredFrame.origin = CGPointMake(0, CGRectGetMidY(self.view.frame)-centeredFrame.size.height/2.0);
                frameAnimation.toValue = [NSValue valueWithCGRect:centeredFrame];
                CGPoint cellTrueOrigin = CGPointMake(cell.frame.origin.x, cell.frame.origin.y - collectionView.contentOffset.y);
                if (cellTrueOrigin.y < collectionView.contentInset.top) {
                    CGFloat diff = collectionView.contentInset.top - cellTrueOrigin.y;
                    POPBasicAnimation *moveDownAnimation = [POPBasicAnimation animationWithPropertyNamed:kPOPScrollViewContentOffset];
                    moveDownAnimation.toValue = [NSValue valueWithCGPoint:CGPointMake(collectionView.contentOffset.x, collectionView.contentOffset.y - diff)];
                    moveDownAnimation.duration = 0.1;
                    moveDownAnimation.completionBlock = ^(POPAnimation *anim, BOOL finished) {
                        frameInMasterView = [self.view convertRect:cell.frame fromView:collectionView];
                        frameAnimation.fromValue = [NSValue valueWithCGRect:frameInMasterView];
                        [self.collectionViewEnlargedImage pop_addAnimation:frameAnimation forKey:@"frame"];
                        dispatch_async(dispatch_get_main_queue(), ^{
                            //do this on next frame so animations can prep the scaling and centering (there is no pop)
                            self.collectionViewEnlargedImage.hidden = NO;
                        });
                    };
                    [collectionView pop_addAnimation:moveDownAnimation forKey:@"contentOffset"];
                } else {
                    [self.collectionViewEnlargedImage pop_addAnimation:frameAnimation forKey:@"frame"];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        //do this on next frame so animations can prep the scaling and centering (there is no pop)
                        self.collectionViewEnlargedImage.hidden = NO;
                    });
                }
            }
            self.collectionViewEnlargedImage.image = image;
            [fullResolutionTimer invalidate];
            fullResolutionTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 block:^{
                [[PhotoManager sharedManager] fullsizeImageIn:[[PhotoManager sharedManager] cameraRollAlbumName]
                                                      atIndex:index
                                              completionBlock:^(UIImage *image, CLLocation *location) {
                                                  self.collectionViewEnlargedImage.image = image;
                                              }];
            } repeats:NO];
        }];
    }
    
    POPSpringAnimation *frameAnimation = [self.collectionViewEnlargedImage pop_animationForKey:@"frame"];
    switch (recognizer.state) {
        case UIGestureRecognizerStateEnded:
        {
            if (frameAnimation == nil) {
                frameAnimation = [POPSpringAnimation animationWithPropertyNamed:kPOPViewFrame];
                [self.collectionViewEnlargedImage pop_addAnimation:frameAnimation forKey:@"frame"];
            }
            frameAnimation.toValue = [NSValue valueWithCGRect:frameInMasterView];
            frameAnimation.completionBlock = ^(POPAnimation *anim, BOOL finished) {
                self.collectionViewEnlargedImage.hidden = YES;
            };
            [fullResolutionTimer invalidate];
            fullResolutionTimer = nil;
            break;
        }
            
        {
        default:
            break;
        }
            
    }
}

- (IBAction)crossTapped
{
    if (scrollViewUp)
        [self hideScrollview];
    else
        [self showScrollview];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    topLayoutConstantMin = -20;
    topLayoutConstantMax = CGRectGetMidY(self.addButton.frame) - 20;
    
    CGRect minimizedFrame = minimizedSchedulePostPanView.frame;
    minimizedFrame.origin.y = topLayoutConstantMax;
    minimizedFrame.size.height = self.view.bounds.size.height - topLayoutConstantMax;
    minimizedSchedulePostPanView.frame = minimizedFrame;
    
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
            captionController.post = selectedPost;
            [self pushController:captionController withSuccess:nil];
        }
        else if ([action isEqualToString:@"view"]) {
            selectedPost = [[PostDBSingleton singleton] postForKey:postKey];
            if (selectedPost != nil) {
                [self showSelectedPost];
            }
        }
    }
    
    CGFloat columns = 4;
    UICollectionViewFlowLayout *layout = (id)self.collectionView.collectionViewLayout;
    layout.itemSize = CGSizeMake((self.view.bounds.size.width - (columns-1)*layout.minimumInteritemSpacing - 1 )/columns, (self.view.bounds.size.width - (columns-1)*layout.minimumInteritemSpacing)/columns);
    
    [NSTimer scheduledTimerWithTimeInterval:60 target:self selector:@selector(reloadScrollView) userInfo:nil repeats:YES];
    [Localytics tagScreen:@"MainScreen"];
    
    [self.addButton animateToType:buttonAddType];
}

- (void)showSelectedPost
{
    NSInteger index = [[[PostDBSingleton singleton] allposts] indexOfObject:selectedPost];
    if (index == NSNotFound) {
        return;
    }
    
    CGFloat border = 4;
    CGFloat columns = 2;
    CGFloat width = (self.scheduledScroller.bounds.size.width - border)/columns;
    CGRect mainRect = CGRectMake(0, border, width, width);
    CGRect currrentFrame = CGRectZero;
    int column = index % 2;
    int row = floor(index / 2.0);
    currrentFrame = CGRectOffset(mainRect, column*(mainRect.size.width+border), row*(mainRect.size.height+border));
    currrentFrame = [self.view convertRect:currrentFrame fromView:self.scheduledScroller];
    [self showSelectedPostWithImage:selectedPost.postImage from:currrentFrame];
}

- (void)postWasLongTapped:(UIGestureRecognizer*)recognizer
{
    scheduledPostModel *thePost = scheduledPosts[recognizer.view.tag-100];
    [self sendPostToInstragramWithKey:thePost.key];
}

- (void)postWasTapped:(UIGestureRecognizer*)recognizer
{
    if (scrollViewUp == NO) {
        [Localytics tagEvent:@"showScrollviewByTappingWhileMinimized"];
        [self showScrollview];
        return;
    }
    
    viewSelected = recognizer.view;
    CGRect viewFrame = viewSelected.frame;
    CGRect frameOfView = [self.scheduledScroller convertRect:viewFrame toView:self.view];
    UIEdgeInsets inset = self.scheduledScroller.contentInset;

    scheduledPostModel *thePost = scheduledPosts[recognizer.view.tag-100];
    selectedPost = thePost;
    
    if (frameOfView.origin.y < inset.top) {
        CGFloat diff = inset.top - frameOfView.origin.y;
        POPBasicAnimation *moveDownAnimation = [POPBasicAnimation animationWithPropertyNamed:kPOPScrollViewContentOffset];
        moveDownAnimation.toValue = [NSValue valueWithCGPoint:CGPointMake(self.scheduledScroller.contentOffset.x, self.scheduledScroller.contentOffset.y - diff)];
        moveDownAnimation.duration = 0.1;
        moveDownAnimation.completionBlock = ^(POPAnimation *anim, BOOL finished) {
            CGRect frameOfView = [self.scheduledScroller convertRect:viewFrame toView:self.view];
            [self showSelectedPostWithImage:selectedPost.postImage from:frameOfView];
        };
        [self.scheduledScroller pop_addAnimation:moveDownAnimation forKey:@"contentOffset"];
    } else {
        [self showSelectedPostWithImage:selectedPost.postImage from:frameOfView];
    }
}

- (void)showSelectedPostWithImage:(UIImage*)image from:(CGRect)rect
{
    returnImageRect = rect;
    
    if (selectedPostShroud == nil) {
        selectedPostShroud = [[UIView alloc] initWithFrame:self.view.bounds];
        selectedPostShroud.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.9];
        selectedPostShroud.alpha = 0.0;
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideSelectedPost)];
        [selectedPostShroud addGestureRecognizer:tap];
        [self.view insertSubview:selectedPostShroud belowSubview:postDetailView];
    }
    
    postDetailView.image.image = image;
    postDetailView.alpha = 1.0;
    
    POPBasicAnimation *alphaAnimation = [selectedPostShroud pop_animationForKey:@"alpha"];
    if (alphaAnimation == nil) {
        alphaAnimation = [POPBasicAnimation animationWithPropertyNamed:kPOPViewAlpha];
        [selectedPostShroud pop_addAnimation:alphaAnimation forKey:@"alpha"];
    }
    else {
        if (alphaAnimation.completionBlock) {
            alphaAnimation.completionBlock(alphaAnimation, NO);
            alphaAnimation.completionBlock = nil;
        }
    }
    alphaAnimation.toValue = [NSNumber numberWithFloat:1.0];
    
    POPSpringAnimation *frameAnimation = [postDetailView pop_animationForKey:@"center"];
    if (frameAnimation == nil) {
        frameAnimation = [POPSpringAnimation animationWithPropertyNamed:kPOPViewCenter];
        frameAnimation.springBounciness = 10.0;
        [postDetailView pop_addAnimation:frameAnimation forKey:@"center"];
    }
    else {
        if (frameAnimation.completionBlock) {
            frameAnimation.completionBlock(frameAnimation, NO);
            frameAnimation.completionBlock = nil;
        }
    }
    frameAnimation.fromValue = [NSValue valueWithCGPoint:CGPointMake(CGRectGetMidX(returnImageRect), CGRectGetMidY(returnImageRect))];
    frameAnimation.toValue = [NSValue valueWithCGPoint:self.view.center];
    
    POPSpringAnimation *scaleAnimation = [postDetailView pop_animationForKey:@"scale"];
    if (scaleAnimation == nil) {
        scaleAnimation = [POPSpringAnimation animationWithPropertyNamed:kPOPViewScaleXY];
        [postDetailView pop_addAnimation:scaleAnimation forKey:@"scale"];
    } else {
        if (scaleAnimation.completionBlock) {
            scaleAnimation.completionBlock(scaleAnimation, NO);
            scaleAnimation.completionBlock = nil;
        }
    }
    scaleAnimation.fromValue = [NSValue valueWithCGPoint:CGPointMake(returnImageRect.size.width / self.view.frame.size.width ,  returnImageRect.size.width / self.view.frame.size.width)];
    scaleAnimation.toValue = [NSValue valueWithCGPoint:CGPointMake(1.0, 1.0)];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        //do this on next frame so animations can prep the scaling and centering (there is no pop)
        postDetailView.hidden = NO;
        viewSelected.hidden = YES;
    });
    
    [postDetailView startGrowing];
    [Localytics tagScreen:@"ScheduledDetail"];
}

- (void)hideSelectedPost
{
    UIView *cachedViewSelected = viewSelected;
    
    POPSpringAnimation *frameAnimation = [postDetailView pop_animationForKey:@"center"];
    if (frameAnimation == nil) {
        frameAnimation = [POPSpringAnimation animationWithPropertyNamed:kPOPViewCenter];
        [postDetailView pop_addAnimation:frameAnimation forKey:@"center"];
    }
    frameAnimation.toValue = [NSValue valueWithCGPoint:CGPointMake(CGRectGetMidX(returnImageRect), CGRectGetMidY(returnImageRect))];
    frameAnimation.completionBlock = ^(POPAnimation *anim, BOOL finished) {
 
    };
    
    POPSpringAnimation *scaleAnimation = [postDetailView pop_animationForKey:@"scale"];
    if (scaleAnimation == nil) {
        scaleAnimation = [POPSpringAnimation animationWithPropertyNamed:kPOPViewScaleXY];
        [postDetailView pop_addAnimation:scaleAnimation forKey:@"scale"];
    }
    scaleAnimation.toValue = [NSValue valueWithCGPoint:CGPointMake(returnImageRect.size.width / self.view.frame.size.width ,  returnImageRect.size.width / self.view.frame.size.width)];
    scaleAnimation.completionBlock = ^(POPAnimation *anim, BOOL finished) {
        if (finished) {
            postDetailView.hidden = YES;
        }
        cachedViewSelected.hidden = NO;
    };
    
    POPBasicAnimation *alphaAnimation = [selectedPostShroud pop_animationForKey:@"alpha"];
     if (alphaAnimation == nil) {
         alphaAnimation = [POPBasicAnimation animationWithPropertyNamed:kPOPViewAlpha];
         [selectedPostShroud pop_addAnimation:alphaAnimation forKey:@"alpha"];
     }
     alphaAnimation.toValue = [NSNumber numberWithFloat:0.0];
     alphaAnimation.completionBlock = ^(POPAnimation *anim, BOOL finished) {
         if (finished) {
             [selectedPostShroud removeFromSuperview];
             selectedPostShroud = nil;
         }
    };
    
    [postDetailView startShrinking];
    [Localytics tagScreen:@"MainScreen"];
}

- (IBAction)snoozeSelectedPost
{
    selectedPost = [[PostDBSingleton singleton] snoozePost:selectedPost];
    
    NSArray *allPosts = [[PostDBSingleton singleton] allposts];
    NSInteger index = [allPosts indexOfObject:selectedPost];
    if (index != NSNotFound) {
        returnImageRect = [self.view convertRect:[self frameForScheduledPostAt:index] fromView:self.scheduledScroller];
    }
    [self hideSelectedPost];

    [Localytics tagEvent:@"SnoozeSelectedPost"];
}

- (IBAction)deleteSelectedPost
{
    [[PostDBSingleton singleton] removePost:selectedPost withDelete:YES];
    
    POPSpringAnimation *scaleAnimation = [postDetailView pop_animationForKey:@"scale"];
    if (scaleAnimation == nil) {
        scaleAnimation = [POPSpringAnimation animationWithPropertyNamed:kPOPViewScaleXY];
        [postDetailView pop_addAnimation:scaleAnimation forKey:@"scale"];
    }
    scaleAnimation.toValue = [NSValue valueWithCGPoint:CGPointMake(2.0, 2.0)];
    scaleAnimation.completionBlock = ^(POPAnimation *anim, BOOL finished) {
        postDetailView.hidden = YES;
    };
    
    POPBasicAnimation *alpahAnimationa = [postDetailView pop_animationForKey:@"alpha"];
    if (alpahAnimationa == nil) {
        alpahAnimationa = [POPBasicAnimation animationWithPropertyNamed:kPOPViewAlpha];
        [postDetailView pop_addAnimation:alpahAnimationa forKey:@"alpha"];
    }
    alpahAnimationa.toValue = @(0.0);
    
    POPBasicAnimation *alphaAnimation = [selectedPostShroud pop_animationForKey:@"alpha"];
    if (alphaAnimation == nil) {
        alphaAnimation = [POPBasicAnimation animationWithPropertyNamed:kPOPViewAlpha];
        [selectedPostShroud pop_addAnimation:alphaAnimation forKey:@"alpha"];
    }
    alphaAnimation.toValue = [NSNumber numberWithFloat:0.0];
    alphaAnimation.duration = 0.2;
    alphaAnimation.completionBlock = ^(POPAnimation *anim, BOOL finished) {
        [selectedPostShroud removeFromSuperview];
    };

    //[self reloadScrollView];
    
    [Localytics tagEvent:@"DeleteSelectedPost"];
}

- (IBAction)sendSelectedPostToInstagram
{
    [self sendPostToInstragramWithKey:selectedPost.key];
}

- (IBAction)editSelectedPost
{
    captionController.comments.text = @"";
    captionController.post = nil;
    captionController.post = selectedPost;
    [captionController resetView];
     
    [self pushController:captionController withSuccess:nil];
    [self hideSelectedPost];
    
    [Localytics tagEvent:@"EditSelectedPost"];
}

- (void)sendPostToInstragramWithKey:(NSString*)postKey
{
    if ([selectedPost.key isEqualToString:postKey] == NO) {
        //find the correct post then
        NSArray *allposts = [[PostDBSingleton singleton] allposts];
        selectedPost = nil;
        for (scheduledPostModel *post in allposts) {
            if ([postKey isEqualToString:post.key]) {
                selectedPost = post;
            }
        }
    }
    
    if (selectedPost  && document == nil) {
        document = [UIDocumentInteractionController interactionControllerWithURL:[NSURL fileURLWithPath:selectedPost.postImageLocation isDirectory:NO]];
        document.UTI = @"com.instagram.exclusivegram";
        document.delegate = self;
        if (selectedPost.postCaption) {
            document.annotation = [NSDictionary dictionaryWithObject:selectedPost.postCaption forKey:@"InstagramCaption"];
        }
        
        BOOL success = [document presentOpenInMenuFromRect:CGRectMake(1, 1, 1, 1) inView:self.view animated:YES];
        if (success) {
            postThatIsBeingPosted = selectedPost;
        }
        
        [Localytics tagEvent:@"ChooseToSendPostToAnotherApp"];
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
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    if (application) {
        [dict setObject:application forKey:@"application"];
    }
    [Localytics tagEvent:@"SentPostToAnotherApp" attributes:dict];
}

- (void)photosUpdated
{
    [self.collectionView reloadData];
}

- (CGRect)frameForScheduledPostAt:(NSInteger)index
{
    CGFloat border = 4;
    CGFloat columns = 2;
    CGFloat width = (self.scheduledScroller.bounds.size.width - border)/columns;
    CGRect mainRect = CGRectMake(0, border, width, width);
    CGRect currrentFrame = CGRectZero;

    int column = index % 2;
    int row = floor(index / 2.0);
    
    currrentFrame = CGRectOffset(mainRect, column*(mainRect.size.width+border), row*(mainRect.size.height+border));
    return currrentFrame;
}

- (void)reloadScrollView
{
    NSArray *oldPosts = [scheduledPosts copy];
    scheduledPosts = [[PostDBSingleton singleton] allposts];
    
    for (UIView *view in self.gestureInstructions) {
        if (scheduledPosts.count > 0) {
            view.hidden = YES;
        } else {
            view.hidden = NO;
        }
    }
    
    NSSet *oldPostSet = [NSSet setWithArray:oldPosts];
    NSSet *newPostSet = [NSSet setWithArray:scheduledPosts];
    
    NSMutableSet *remainingPosts = [NSMutableSet setWithSet:newPostSet];
    [remainingPosts intersectSet:oldPostSet];
    
    NSMutableSet *newPosts = [NSMutableSet setWithSet:newPostSet];
    [newPosts minusSet:oldPostSet];
    
    NSMutableSet *deletedPosts = [NSMutableSet setWithSet:oldPostSet];
    [deletedPosts minusSet:newPostSet];
    
    NSLog(@"new: %@", newPosts);
    NSLog(@"deleted: %@", deletedPosts);
    
    
    for (scheduledPostModel *post in [deletedPosts allObjects]) {
        NSInteger oldIndex = [oldPosts indexOfObject:post];
        UIView *subview = [self.scheduledScroller viewWithTag:oldIndex+100];
        POPSpringAnimation *popoutAnimation = [POPSpringAnimation animationWithPropertyNamed:kPOPViewScaleXY];
        popoutAnimation.fromValue = [NSValue valueWithCGPoint:CGPointMake(1, 1)];
        popoutAnimation.toValue = [NSValue valueWithCGPoint:CGPointMake(0, 0)];
        popoutAnimation.beginTime = CACurrentMediaTime();
        popoutAnimation.completionBlock = ^(POPAnimation *anim, BOOL finished) {
            [subview removeFromSuperview];
        };
        [subview pop_addAnimation:popoutAnimation forKey:@"scale"];
        [viewsInScrollView removeObject:subview];
    }
    
    for (scheduledPostModel *post in [remainingPosts allObjects]) {
        NSInteger oldIndex = [oldPosts indexOfObject:post];
        NSInteger newIndex = [scheduledPosts indexOfObject:post];
        ScheduledPostImageView *postsView = (ScheduledPostImageView*)[self.scheduledScroller viewWithTag:oldIndex+100];
        
        if (oldIndex != newIndex) {
            //CGRect oldFrame = [self frameForScheduledPostAt:oldIndex];
            CGRect newFrame = [self frameForScheduledPostAt:newIndex];
            POPBasicAnimation *translationAnimation = [POPBasicAnimation animationWithPropertyNamed:kPOPViewFrame];
            translationAnimation.toValue = [NSValue valueWithCGRect:newFrame];
            translationAnimation.completionBlock = ^(POPAnimation *anim, BOOL finished) {
                postsView.tag = newIndex+100;
            };
            [postsView pop_addAnimation:translationAnimation forKey:@"frame"];
        }
        
        [postsView setWithDate:post.postTime];
    }
    
    for(scheduledPostModel *post in [newPosts allObjects]) {
        NSInteger index = [scheduledPosts indexOfObject:post];
        UINib *nibFile = [UINib nibWithNibName:@"ScheduledPostImageView" bundle:nil];
        NSArray *contentsOfNib = [nibFile instantiateWithOwner:nil options:nil];
        ScheduledPostImageView *view = contentsOfNib[0];
        view.frame = [self frameForScheduledPostAt:index];
        view.imageView.image = post.postImage;
        [view setWithDate:post.postTime];
        view.tag = index + 100;
        //view.hidden = YES;
        [view setNeedsLayout];
        [self.scheduledScroller insertSubview:view aboveSubview:shroud];
        [viewsInScrollView addObject:view];
        
        UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(postWasLongTapped:)];
        [view addGestureRecognizer:longPress];
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(postWasTapped:)];
        [view addGestureRecognizer:tap];

        POPSpringAnimation *popinAnimation = [POPSpringAnimation animationWithPropertyNamed:kPOPViewScaleXY];
        popinAnimation.fromValue = [NSValue valueWithCGPoint:CGPointMake(0, 0)];
        popinAnimation.toValue = [NSValue valueWithCGPoint:CGPointMake(1, 1)];
        popinAnimation.beginTime = CACurrentMediaTime();
        if (firstScheduledPostLoad) {
            popinAnimation.beginTime += index * 0.2;
        }
        popinAnimation.completionBlock = ^(POPAnimation *anim, BOOL finished) {
            [view setNeedsLayout];
        };
        popinAnimation.animationDidStartBlock = ^(POPAnimation *animation) {
            view.hidden = NO;
        };
        //[view pop_addAnimation:popinAnimation forKey:@"scale"];
        
        POPBasicAnimation *fadeinAnimation = [POPBasicAnimation animationWithPropertyNamed:kPOPViewAlpha];
        fadeinAnimation.toValue = @(1.0);
        [view pop_addAnimation:fadeinAnimation forKey:@"alpha"];
    }
    
    CGRect frameOfLastScheduledPost = [self frameForScheduledPostAt:scheduledPosts.count-1];
    self.scheduledScroller.contentSize = CGSizeMake(self.scheduledScroller.bounds.size.width,
                                                    MAX(frameOfLastScheduledPost.origin.y + frameOfLastScheduledPost.size.height,
                                                        0));
    shroud.frame = CGRectMake(0, 0, self.scheduledScroller.contentSize.width, self.scheduledScroller.contentSize.height + self.scheduledScroller.bounds.size.height);
    
    firstScheduledPostLoad = NO;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (scrollView != self.scheduledScroller) {
        return;
    }
    
    if (scrollView.contentOffset.y < -1 * scrollView.contentInset.top && scrollViewUp == YES) {
        CGFloat expansionSpace = scrollView.contentOffset.y - scrollView.contentInset.top*-1;
        CGFloat maxDragDown = 250;
        
        CGFloat alphaPercent = ABS(expansionSpace/maxDragDown);
        CGFloat scale = MIN(1.0,alphaPercent*0.1+0.95);
        self.collectionView.transform = CGAffineTransformMakeScale(scale, scale);
        self.collectionView.alpha = MAX(0.5,alphaPercent);
        //NSLog(@"alphaPercent: %f", alphaPercent);
        
        for (UIView *view in self.gestureInstructions) {
            view.alpha = 1-alphaPercent;
        }
    }
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset
{
    if (scrollView != self.scheduledScroller) {
        return;
    }
    
    if ((velocity.y < -1.0 && scrollView.contentOffset.y < -100) || (scrollView.contentOffset.y < -150 && velocity.y <= 0)) {
        *targetContentOffset = CGPointZero;
        self.topConstraint.constant = scrollView.contentOffset.y * -1;
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
    [self.addButton animateToType:buttonCloseType];
    
    for (UIView *view in self.gestureInstructions) {
        view.alpha = 0;
    }

    [self authorizePhotos];
    scrollViewUp = NO;
    
    minimizedSchedulePostPanView.userInteractionEnabled = YES;
    
    //---- Scroll View ---

    POPSpringAnimation *scheduldPostVerticalanimation = [POPSpringAnimation animationWithPropertyNamed:kPOPLayoutConstraintConstant];
    scheduldPostVerticalanimation.springBounciness = 8;
    scheduldPostVerticalanimation.velocity = @(velocity);
    scheduldPostVerticalanimation.toValue = @(topLayoutConstantMax);
    if ([self.topConstraint pop_animationForKey:@"layout"]) {
        POPSpringAnimation *existingAnimation = [self.topConstraint pop_animationForKey:@"layout"];
        existingAnimation.toValue =scheduldPostVerticalanimation.toValue;
    } else
        [self.topConstraint pop_addAnimation:scheduldPostVerticalanimation forKey:@"layout"];
    
    POPSpringAnimation *scheduledPostInset = [POPSpringAnimation animationWithPropertyNamed:kPOPScrollViewContentInset];
    scheduledPostInset.toValue = [NSValue valueWithUIEdgeInsets:UIEdgeInsetsMake(0, 0, 0, 0)];
    scheduledPostInset.springBounciness = scheduldPostVerticalanimation.springBounciness;
    scheduledPostInset.velocity = [NSValue valueWithUIEdgeInsets:UIEdgeInsetsMake(velocity, 0, 0, 0)];
    if ([self.scheduledScroller pop_animationForKey:@"inset"]) {
        POPSpringAnimation *existingAnimation = [self.scheduledScroller pop_animationForKey:@"inset"];
        existingAnimation.toValue = scheduledPostInset.toValue;
    } else
        [self.scheduledScroller pop_addAnimation:scheduledPostInset forKey:@""];
    
    POPSpringAnimation *scheduledPostOffset = [POPSpringAnimation animationWithPropertyNamed:kPOPScrollViewContentOffset];
    scheduledPostOffset.toValue = [NSValue valueWithCGPoint:CGPointMake(0, 4)];
    scheduledPostOffset.springBounciness = scheduldPostVerticalanimation.springBounciness;
    scheduledPostOffset.velocity = [NSValue valueWithCGPoint:CGPointMake(0, velocity)];
    if ([self.scheduledScroller pop_animationForKey:@"offset"]) {
        POPSpringAnimation *existingAnimation = [self.scheduledScroller pop_animationForKey:@"offset"];
        existingAnimation.toValue = scheduledPostOffset.toValue;
    } else
        [self.scheduledScroller pop_addAnimation:scheduledPostOffset forKey:@"offset"];
    
    POPSpringAnimation *scheduledPostCorderradiusAnimation = [POPSpringAnimation animationWithPropertyNamed:kPOPLayerCornerRadius];
    scheduledPostCorderradiusAnimation.toValue = @(5.0);
    scheduledPostCorderradiusAnimation.springBounciness = 8.0;
    scheduledPostCorderradiusAnimation.velocity = @(velocity);
    if ([self.scheduledScroller.layer pop_animationForKey:@"cornerRadius"]) {
        POPSpringAnimation *existingAnimation = [self.scheduledScroller.layer pop_animationForKey:@"cornerRadius"];
        existingAnimation.toValue = scheduledPostCorderradiusAnimation.toValue;
    } else
        [self.scheduledScroller.layer pop_addAnimation:scheduledPostCorderradiusAnimation forKey:@"cornerRadius"];
    
    POPSpringAnimation *scheduledPostScaleAnimation = [POPSpringAnimation animationWithPropertyNamed:kPOPViewScaleXY];
    scheduledPostScaleAnimation.toValue = [NSValue valueWithCGPoint:CGPointMake(1.0, 1.0)];
    scheduledPostOffset.velocity = [NSValue valueWithCGPoint:CGPointMake(velocity, velocity)];
    if ([self.scheduledScroller pop_animationForKey:@"scaling"]) {
        POPSpringAnimation *existingAnimation = [self.scheduledScroller pop_animationForKey:@"scaling"];
        existingAnimation.toValue = scheduledPostScaleAnimation.toValue;
    } else
        [self.scheduledScroller pop_addAnimation:scheduledPostScaleAnimation forKey:@"scaling"];
    
    //---- Collection View ----
    POPSpringAnimation *collectionAlphaAnimation = [POPSpringAnimation animationWithPropertyNamed:kPOPViewAlpha];
    collectionAlphaAnimation.toValue = @(1.0);
    [self.collectionView pop_addAnimation:collectionAlphaAnimation forKey:@"alpha"];
    
    POPSpringAnimation *collectionViewScaleAnimation = [POPSpringAnimation animationWithPropertyNamed:kPOPLayerScaleXY];
    collectionViewScaleAnimation.toValue = [NSValue valueWithCGPoint:CGPointMake(1, 1)];
    collectionViewScaleAnimation.velocity = [NSValue valueWithCGPoint:CGPointMake(-1 * velocity, -1 * velocity)];
    [self.collectionView.layer pop_addAnimation:collectionViewScaleAnimation forKey:@"scale"];

    if (scrollViewUp) {
        POPSpringAnimation *offset = [POPSpringAnimation animationWithPropertyNamed:kPOPScrollViewContentOffset];
        offset.toValue = [NSValue valueWithCGPoint:CGPointMake(0, (self.collectionView.contentInset.top+1)*-1)];
        offset.springBounciness = scheduldPostVerticalanimation.springBounciness;
        offset.velocity = [NSValue valueWithCGPoint:CGPointMake(0, velocity)];
        [self.collectionView pop_addAnimation:offset forKey:@"offset"];
        
        POPSpringAnimation *inset = [POPSpringAnimation animationWithPropertyNamed:kPOPScrollViewContentInset];
        inset.toValue = [NSValue valueWithUIEdgeInsets:UIEdgeInsetsMake(initialinsets.top+1, 0, 0, 0)];
        inset.springBounciness = scheduldPostVerticalanimation.springBounciness;
        inset.velocity = [NSValue valueWithUIEdgeInsets:UIEdgeInsetsMake(velocity, 0, 0, 0)];
        [self.collectionView pop_addAnimation:inset forKey:@"inset"];
    }
    
    if (velocity == 0) {
        [Localytics tagEvent:@"ShowImageLibrary" attributes:[NSDictionary dictionaryWithObject:@"button" forKey:@"source"]];
    } else {
        NSDictionary *dict = [NSDictionary dictionaryWithObjects:@[@"gesture", [NSNumber numberWithFloat:velocity]] forKeys:@[@"source", @"velocity"]];
        [Localytics tagEvent:@"ShowImageLibrary" attributes:dict];
    }
    [Localytics tagScreen:@"PhotoLibrary"];
}

- (IBAction)showScrollview
{
    minimizedSchedulePostPanView.userInteractionEnabled = NO;
    
    [self.addButton animateToType:buttonAddType];
    
    scrollViewUp = YES;
    
    //---- Scroll View ---
    POPSpringAnimation *scheduldPostVerticalanimation = [POPSpringAnimation animationWithPropertyNamed:kPOPLayoutConstraintConstant];
    scheduldPostVerticalanimation.springBounciness = 8;
    scheduldPostVerticalanimation.toValue = @(topLayoutConstantMin);
    if ([self.topConstraint pop_animationForKey:@"layout"]) {
        POPSpringAnimation *existingAnimation = [self.topConstraint pop_animationForKey:@"layout"];
        existingAnimation.toValue = scheduldPostVerticalanimation.toValue;
    } else
        [self.topConstraint pop_addAnimation:scheduldPostVerticalanimation forKey:@"layout"];
    
    POPBasicAnimation *scheduledContentOffsetAnimation = [POPBasicAnimation animationWithPropertyNamed:kPOPScrollViewContentOffset];
    scheduledContentOffsetAnimation.toValue = [NSValue valueWithCGPoint:CGPointMake(0, -1*initialinsets.top)];
    if ([self.scheduledScroller pop_animationForKey:@"offset"]) {
        POPSpringAnimation *existingAnimation = [self.scheduledScroller pop_animationForKey:@"offset"];
        existingAnimation.toValue = scheduledContentOffsetAnimation.toValue;
    } else
        [self.scheduledScroller pop_addAnimation:scheduledContentOffsetAnimation forKey:@"offset"];
    
    POPSpringAnimation *scheduledPostInsetAnimation = [POPSpringAnimation animationWithPropertyNamed:kPOPScrollViewContentInset];
    scheduledPostInsetAnimation.toValue = [NSValue valueWithUIEdgeInsets:initialinsets];
    scheduledPostInsetAnimation.springBounciness = 8.0;
    if ([self.scheduledScroller pop_animationForKey:@"inset"]) {
        POPSpringAnimation *existingAnimation = [self.scheduledScroller pop_animationForKey:@"inset"];
        existingAnimation.toValue = scheduledPostInsetAnimation.toValue;
    } else
        [self.scheduledScroller pop_addAnimation:scheduledPostInsetAnimation forKey:@"inset"];
    
    POPSpringAnimation *scheduledPostCorderradiusAnimation = [POPSpringAnimation animationWithPropertyNamed:kPOPLayerCornerRadius];
    scheduledPostCorderradiusAnimation.toValue = @(0.0);
    scheduledPostCorderradiusAnimation.springBounciness = 8.0;
    if ([self.scheduledScroller.layer pop_animationForKey:@"cornerRadius"]) {
        POPSpringAnimation *existingAnimation = [self.scheduledScroller.layer pop_animationForKey:@"cornerRadius"];
        existingAnimation.toValue = scheduledPostCorderradiusAnimation.toValue;
    } else
    [self.scheduledScroller.layer pop_addAnimation:scheduledPostCorderradiusAnimation forKey:@"cornerRadius"];
    
    POPSpringAnimation *scheduledPostScaleAnimation = [POPSpringAnimation animationWithPropertyNamed:kPOPViewScaleXY];
    scheduledPostScaleAnimation.toValue = [NSValue valueWithCGPoint:CGPointMake(1.0, 1.0)];
    if ([self.scheduledScroller pop_animationForKey:@"scaling"]) {
        POPSpringAnimation *existingAnimation = [self.scheduledScroller pop_animationForKey:@"scaling"];
        existingAnimation.toValue = scheduledPostScaleAnimation.toValue;
    } else
        [self.scheduledScroller pop_addAnimation:scheduledPostScaleAnimation forKey:@"scaling"];
    
    //---- Collection View ----
    POPSpringAnimation *collectionViewOffsetAnimation = [POPSpringAnimation animationWithPropertyNamed:kPOPScrollViewContentOffset];
    collectionViewOffsetAnimation.toValue = [NSValue valueWithCGPoint:CGPointMake(0, -1*initialinsets.top)];
    collectionViewOffsetAnimation.springBounciness = 8.0;
    [self.collectionView pop_addAnimation:collectionViewOffsetAnimation forKey:@"offset"];
    
    POPSpringAnimation *collectionViewInsetAnimation = [POPSpringAnimation animationWithPropertyNamed:kPOPScrollViewContentInset];
    collectionViewInsetAnimation.toValue = [NSValue valueWithUIEdgeInsets:initialinsets];
    collectionViewInsetAnimation.springBounciness = 8.0;
    [self.collectionView pop_addAnimation:collectionViewInsetAnimation forKey:@"inset"];
    
    POPSpringAnimation *collectionAlphaAnimation = [POPSpringAnimation animationWithPropertyNamed:kPOPViewAlpha];
    collectionAlphaAnimation.toValue = @(0.0);
    [self.collectionView pop_addAnimation:collectionAlphaAnimation forKey:@"alpha"];
    
    [Localytics tagScreen:@"MainScreen"];
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
                                              captionController.initialLocation = location;
                                              captionController.locationPickerViewController.initialLocation = location;
                                          }];
            
        });
    }];
    
    [Localytics tagEvent:@"selectedPhoto"];
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
            if (xTranslation < 0 && scrollViewUp == NO)
                [self moveScrollviewBy:xTranslation withVelocity:xVelocity];
            break;
            
        case UIGestureRecognizerStateEnded:
            if (xTranslation > 0 && xVelocity > 0 && recognizer == leftEdgeGesture) {
                edgeSwipeSameDirection = YES;
            }
            if (xTranslation < 0 && xVelocity < 0 && recognizer == rightEdgeGesture) {
                edgeSwipeSameDirection = YES;
            }
            BOOL xTranslationOverHalf = ABS(xTranslation) > self.view.frame.size.width/2.0;
            BOOL xVelocityOverThreshold = ABS(xVelocity) > 50;
            BOOL xTranslationOverThird = ABS(xTranslation) > self.view.frame.size.width/3.0;
            BOOL xVelocityOverThresholdWithRequiredTranslation = xVelocityOverThreshold && xTranslationOverThird;
            if ((xTranslationOverHalf || xVelocityOverThresholdWithRequiredTranslation) && edgeSwipeSameDirection)  {
                if (xTranslation > 0) {
                    animation.toValue = [NSValue valueWithCGRect:CGRectMake(captionController.view.frame.size.width, 0, captionController.view.frame.size.width, captionController.view.frame.size.height)];
                    [Localytics tagEvent:@"closeEditWithSwipeFromLeftEdge"];
                } else {
                    animation.toValue = [NSValue valueWithCGRect:CGRectMake(-1*captionController.view.frame.size.width, 0, captionController.view.frame.size.width, captionController.view.frame.size.height)];
                    [Localytics tagEvent:@"closeEditWithSwipeFromRightEdge"];
                    [captionController schedulePost];
                }
                animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
                animation.completionBlock = ^(POPAnimation *anim, BOOL finished) {
                    [self removeController:captionController];
                };
                if (ABS(xVelocity) < 500) {
                    xVelocity = 500;
                }
                animation.duration = ABS((captionController.view.frame.size.width - xTranslation) / xVelocity);
            } else {
                animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
                animation.toValue = [NSValue valueWithCGRect:CGRectMake(0, 0, captionController.view.frame.size.width, captionController.view.frame.size.height)];
                if (ABS(xVelocity) < 500) {
                    xVelocity = 500;
                }
                animation.duration = ABS((xTranslation) / xVelocity);
            }
            [captionController.view pop_addAnimation:animation forKey:@"slide"];
            break;
                                            
        default:
            captionController.view.frame = CGRectMake(xTranslation, 0, captionController.view.frame.size.width, captionController.view.frame.size.height);
            if (xTranslation < 0 && scrollViewUp == NO)
                [self moveScrollviewBy:xTranslation*-1 withVelocity:xVelocity*-1];
            break;
    }
}

- (void)moveScrollviewBy:(CGFloat)value withVelocity:(CGFloat)velocity
{
    CGFloat newLocation = topLayoutConstantMax - value;
    if (newLocation > topLayoutConstantMax) {
        newLocation = topLayoutConstantMax;
    }
    if (newLocation < topLayoutConstantMin) {
        newLocation = topLayoutConstantMin;
    }
    
    POPSpringAnimation *scheduldPostVerticalanimation = [POPSpringAnimation animationWithPropertyNamed:kPOPLayoutConstraintConstant];
    scheduldPostVerticalanimation.springBounciness = 8;
    scheduldPostVerticalanimation.velocity = @(velocity);
    scheduldPostVerticalanimation.toValue = @(newLocation);
    if ([self.topConstraint pop_animationForKey:@"layout"]) {
        POPSpringAnimation *existingAnimation = [self.topConstraint pop_animationForKey:@"layout"];
        existingAnimation.toValue = scheduldPostVerticalanimation.toValue;
    } else
        [self.topConstraint pop_addAnimation:scheduldPostVerticalanimation forKey:@"layout"];
}

- (void)panScroll:(UIPanGestureRecognizer*)recognizer
{
    CGFloat yPan = [recognizer translationInView:self.view].y * -1;
    CGFloat yPanVelocity = [recognizer velocityInView:self.view].y * -1;
    
    POPSpringAnimation *scheduldPostVerticalanimation = [POPSpringAnimation animationWithPropertyNamed:kPOPLayoutConstraintConstant];
    scheduldPostVerticalanimation.springBounciness = 8;
    scheduldPostVerticalanimation.velocity = @(yPanVelocity);
    scheduldPostVerticalanimation.toValue = @(topLayoutConstantMax - yPan);
    if ([self.topConstraint pop_animationForKey:@"layout"]) {
        POPSpringAnimation *existingAnimation = [self.topConstraint pop_animationForKey:@"layout"];
        existingAnimation.toValue = scheduldPostVerticalanimation.toValue;
    } else
        [self.topConstraint pop_addAnimation:scheduldPostVerticalanimation forKey:@"layout"];
    
    switch (recognizer.state) {
        case UIGestureRecognizerStateEnded:
            //decide if we drop back down or move up
            if (yPanVelocity > 0 || yPan > (topLayoutConstantMax - topLayoutConstantMin)/2.0) {
                [self showScrollview];
            } else {
                [self hideScrollview];
            }
            break;
            
        default:
            break;
    }
}

- (void)pushController:(UIViewController*)controller withSuccess:(void (^)(void))success
{
    CGRect initialFrame = CGRectMake(self.view.bounds.size.width, 0, self.view.bounds.size.width, self.view.bounds.size.height);
    
    [self addChildViewController:controller];
    [self.view addSubview:controller.view];

    controller.view.frame = initialFrame;
    
    if (pushedControllerShroud != nil) {
        [pushedControllerShroud removeFromSuperview];
    }
    pushedControllerShroud = [[UIView alloc] initWithFrame:self.view.bounds];
    pushedControllerShroud.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.9];
    pushedControllerShroud.alpha = 0.0;

    [self.view insertSubview:pushedControllerShroud belowSubview:self.menuBar];
    
    [RACObserve(captionController, view.frame) subscribeNext:^(NSValue *frame) {
        CGRect viewsFrame = [frame CGRectValue];
        CGFloat percentMoved = 1- ABS(viewsFrame.origin.x)/controller.view.frame.size.width;
        pushedControllerShroud.alpha = percentMoved;
    }];
    
    POPBasicAnimation *animation = [POPBasicAnimation animationWithPropertyNamed:kPOPViewFrame];
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
    animation.fromValue = [NSValue valueWithCGRect:initialFrame];
    animation.duration = 0.4;
    animation.toValue = [NSValue valueWithCGRect:self.view.bounds];
    animation.completionBlock = ^(POPAnimation *anim, BOOL finished) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [captionController didMoveToParentViewController:self];
            if(success) {
                success();
            }
        });
    };
    
    leftEdgeGesture = [[UIScreenEdgePanGestureRecognizer alloc] initWithTarget:self action:@selector(edgeSwipe:)];
    leftEdgeGesture.edges = UIRectEdgeLeft;
    leftEdgeGesture.delaysTouchesBegan = NO;
    leftEdgeGesture.delegate = self;
    [self.view addGestureRecognizer:leftEdgeGesture];
    
    rightEdgeGesture = [[UIScreenEdgePanGestureRecognizer alloc] initWithTarget:self action:@selector(edgeSwipe:)];
    rightEdgeGesture.edges = UIRectEdgeRight;
    rightEdgeGesture.delaysTouchesBegan = NO;
    rightEdgeGesture.delegate = self;
    [self.view addGestureRecognizer:rightEdgeGesture];
    
    [controller.view pop_addAnimation:animation forKey:@"frame"];
    
    [Localytics tagScreen:@"CaptionEditor"];
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
    
    POPBasicAnimation *animation = [controller.view pop_animationForKey:@"frame"];
    if (animation == nil) {
        animation =  [POPBasicAnimation animationWithPropertyNamed:kPOPViewFrame];
        animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
        animation.duration = 0.2;
        [controller.view pop_addAnimation:animation forKey:@"frame"];
    }
    animation.toValue = [NSValue valueWithCGRect:exitFrame];
    animation.completionBlock = ^(POPAnimation *anim, BOOL finished) {
        [self removeController:controller];
        if(success) {
            success();
        }
    };
    
    [self.view endEditing:YES];
    [Localytics tagScreen:@"MainScreen"];
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
    [pushedControllerShroud removeFromSuperview];
    pushedControllerShroud = nil;
    
    [self.view removeGestureRecognizer:leftEdgeGesture];
    [self.view removeGestureRecognizer:rightEdgeGesture];
}

- (void)newPostWasAdded:(NSNotification*)notification
{
    [self reloadScrollView];
    [self showScrollview];
    
    if (notification.userInfo) {
        //means this is a added post notification
        [self popController:captionController withDirection:UIRectEdgeLeft withSuccess:nil];
    }
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

- (void)notifiedShowPost:(NSNotification*)notification
{
    NSDictionary *userInfo = notification.userInfo;
    NSString *key = [userInfo objectForKey:@"key"];
    selectedPost = [[PostDBSingleton singleton] postForKey:key];
    if (selectedPost && scrollViewUp && pushedControllerShroud == nil) {
        //aka user is doing nothing
        [self showSelectedPost];
    }
}

@end
