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
    
    if (scheduledPosts.count > 0) {
        for (UIView *view in self.gestureInstructions) {
            view.hidden = YES;
        }
    }
    
    initialinsets = UIEdgeInsetsMake(64, 0, 0, 0);
    self.scheduledScroller.contentInset = initialinsets;
    self.scheduledScroller.scrollIndicatorInsets = self.scheduledScroller.contentInset;
    
    shroud = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.scheduledScroller.bounds.size.width, self.scheduledScroller.bounds.size.height)];
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
    
    [RACObserve(self, topConstraint.constant) subscribeNext:^(NSNumber *layoutConstant) {
        CGFloat value = [layoutConstant floatValue];
        CGFloat percent = (value - topLayoutConstantMin) / (topLayoutConstantMax - topLayoutConstantMin);
        
        self.addButton.transform = [self transformForAddButtonWithPercent:percent];
    }];
    
    scrollViewUp = YES;
    
    panRecognizerForMinimzedScrollView = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panScroll:)];
    panRecognizerForMinimzedScrollView.enabled = NO;
    [self.scheduledScroller addGestureRecognizer:panRecognizerForMinimzedScrollView];
}
     
- (CGAffineTransform)transformForAddButtonWithPercent:(CGFloat)percent
{
    CGAffineTransform transformer = CGAffineTransformIdentity;
    transformer = CGAffineTransformTranslate(transformer, -1 * (self.view.frame.size.width - self.addButton.frame.size.width/2.0 - 8) * percent, 0);
    transformer = CGAffineTransformRotate(transformer, DEGREES_TO_RADIANS(-45*percent));
    return transformer;
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
    topLayoutConstantMax = self.view.bounds.size.height - (64);
    
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
    scheduledPostModel *thePost = scheduledPosts[recognizer.view.tag];
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

    scheduledPostModel *thePost = scheduledPosts[recognizer.view.tag];
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
    
    if (selectedPostShroud != nil) {
        [selectedPostShroud removeFromSuperview];
    }
    selectedPostShroud = [[UIView alloc] initWithFrame:self.view.bounds];
    selectedPostShroud.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.9];
    selectedPostShroud.alpha = 0.0;
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideSelectedPost)];
    [selectedPostShroud addGestureRecognizer:tap];
    [self.view insertSubview:selectedPostShroud belowSubview:postDetailView];
    
    postDetailView.image.image = image;
    postDetailView.alpha = 1.0;
    
    POPBasicAnimation *alphaAnimation = [selectedPostShroud pop_animationForKey:@"alpha"];
    if (alphaAnimation == nil) {
        alphaAnimation = [POPBasicAnimation animationWithPropertyNamed:kPOPViewAlpha];
        [selectedPostShroud pop_addAnimation:alphaAnimation forKey:@"alpha"];
    }
    alphaAnimation.toValue = [NSNumber numberWithFloat:1.0];
    
    POPSpringAnimation *frameAnimation = [postDetailView pop_animationForKey:@"frame"];
    if (frameAnimation == nil) {
        frameAnimation = [POPSpringAnimation animationWithPropertyNamed:kPOPViewCenter];
        frameAnimation.springBounciness = 10.0;
        [postDetailView pop_addAnimation:frameAnimation forKey:@"frame"];
    }
    frameAnimation.fromValue = [NSValue valueWithCGPoint:CGPointMake(CGRectGetMidX(returnImageRect), CGRectGetMidY(returnImageRect))];
    frameAnimation.toValue = [NSValue valueWithCGPoint:self.view.center];

    
    POPSpringAnimation *scaleAnimation = [postDetailView pop_animationForKey:@"scale"];
    if (scaleAnimation == nil) {
        scaleAnimation = [POPSpringAnimation animationWithPropertyNamed:kPOPViewScaleXY];
        [postDetailView pop_addAnimation:scaleAnimation forKey:@"scale"];
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
    POPSpringAnimation *frameAnimation = [postDetailView pop_animationForKey:@"frame"];
    if (frameAnimation == nil) {
        frameAnimation = [POPSpringAnimation animationWithPropertyNamed:kPOPViewCenter];
        [postDetailView pop_addAnimation:frameAnimation forKey:@"frame"];
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
        postDetailView.hidden = YES;
        viewSelected.hidden = NO;
        
    };
    
    POPBasicAnimation *alphaAnimation = [selectedPostShroud pop_animationForKey:@"alpha"];
     if (alphaAnimation == nil) {
         alphaAnimation = [POPBasicAnimation animationWithPropertyNamed:kPOPViewAlpha];
         [selectedPostShroud pop_addAnimation:alphaAnimation forKey:@"alpha"];
     }
     alphaAnimation.toValue = [NSNumber numberWithFloat:0.0];
     alphaAnimation.completionBlock = ^(POPAnimation *anim, BOOL finished) {
         [selectedPostShroud removeFromSuperview];
         selectedPostShroud = nil;
    };
    
    [postDetailView startShrinking];
    [Localytics tagScreen:@"MainScreen"];
}

- (IBAction)snoozeSelectedPost
{
    [[PostDBSingleton singleton] snoozePost:selectedPost];
    [self hideSelectedPost];
    [self reloadScrollView];
    
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

    [self reloadScrollView];
    
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
    
    
    UIFont *font = [UIFont fontWithName:@"HelveticaNeue-Thin" size:68];
    UIFont *smallFont = [UIFont fontWithName:@"HelveticaNeue-Thin" size:40];
    if (self.view.frame.size.width < 370) {
        font = [UIFont fontWithName:@"HelveticaNeue-Thin" size:55];
        smallFont = [UIFont fontWithName:@"HelveticaNeue-Thin" size:30];
    }
    
    UIFontDescriptor *const existingDescriptor = [font fontDescriptor];
    NSDictionary *const fontAttributes = @{
                                           // Here comes that array of dictionaries each containing UIFontFeatureTypeIdentifierKey
                                           // and UIFontFeatureSelectorIdentifierKey that the reference mentions.
                                           UIFontDescriptorFeatureSettingsAttribute: @[
                                                   @{
                                                       UIFontFeatureTypeIdentifierKey: @(kNumberSpacingType),
                                                       UIFontFeatureSelectorIdentifierKey: @(kProportionalNumbersSelector)
                                                       }]
                                           };
    
    UIFontDescriptor *const proportionalDescriptor = [existingDescriptor fontDescriptorByAddingAttributes: fontAttributes];
    UIFont *const proportionalFont = [UIFont fontWithDescriptor: proportionalDescriptor size: [font pointSize]];
    
    NSDictionary *attrsDictionary =[NSDictionary dictionaryWithObject:proportionalFont forKey:NSFontAttributeName];
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
    
    if (scheduledPosts.count > 0) {
        for (UIView *view in self.gestureInstructions) {
            view.hidden = YES;
        }
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
        id colorBottom = (id)[[UIColor colorWithWhite:0.0 alpha:0.5] CGColor];
        gradient.colors = @[colorTop, colorBottom];
        NSNumber *stopTop = [NSNumber numberWithFloat:0.2];
        NSNumber *stopBottom = [NSNumber numberWithFloat:0.9];
        gradient.locations = @[stopTop, stopBottom];
        gradient.frame = newImage.bounds;
        [newImage.layer insertSublayer:gradient above:imageView.layer];
        
        CGRect timeLabelRect = CGRectMake(5, mainRect.size.height - (55+5), imageRect.size.width - 5, 55);
        UILabel *timeLabel = [[UILabel alloc] initWithFrame:timeLabelRect];
        timeLabel.textColor = [UIColor whiteColor];
        timeLabel.attributedText = [self stringForDate:post.postTime];
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
    
    if ((velocity.y < -1.0 && scrollView.contentOffset.y < -100) || (scrollView.contentOffset.y < -150)) {
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
    for (UIView *view in self.gestureInstructions) {
        view.alpha = 0;
    }
    
    if (velocity == 0) {
        [Localytics tagEvent:@"ShowImageLibrary" attributes:[NSDictionary dictionaryWithObject:@"button" forKey:@"source"]];
    } else {
        NSDictionary *dict = [NSDictionary dictionaryWithObjects:@[@"gesture", [NSNumber numberWithFloat:velocity]] forKeys:@[@"source", @"velocity"]];
        [Localytics tagEvent:@"ShowImageLibrary" attributes:dict];
    }

    [self authorizePhotos];
    scrollViewUp = NO;
    
    self.scheduledScroller.clipsToBounds = YES;
    
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
    
    POPSpringAnimation *collectionViewScaleAnimation = [POPSpringAnimation animationWithPropertyNamed:kPOPLayerScaleXY];
    collectionViewScaleAnimation.toValue = [NSValue valueWithCGPoint:CGPointMake(1, 1)];
    collectionViewScaleAnimation.velocity = [NSValue valueWithCGPoint:CGPointMake(-1 * velocity, -1 * velocity)];
    [self.collectionView.layer pop_addAnimation:collectionViewScaleAnimation forKey:@"scale"];
    
    panRecognizerForMinimzedScrollView.enabled = YES;
    [Localytics tagScreen:@"PhotoLibrary"];
}

- (IBAction)showScrollview
{
    panRecognizerForMinimzedScrollView.enabled = NO;
    
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
    scheduledContentOffsetAnimation.toValue = [NSValue valueWithCGPoint:CGPointMake(0, -64)];
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
    collectionViewOffsetAnimation.toValue = [NSValue valueWithCGPoint:CGPointMake(0, -64)];
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
            if (xTranslation < 0)
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
            if (xTranslation < 0)
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
    
    [Localytics tagEvent:@"selectedPhoto"];
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
    
    [self.view removeGestureRecognizer:leftEdgeGesture];
    [self.view removeGestureRecognizer:rightEdgeGesture];
}

- (void)newPostWasAdded
{
    [self reloadScrollView];
    [self showScrollview];
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

- (void)notifiedShowPost:(NSNotification*)notification
{
    NSDictionary *userInfo = notification.userInfo;
    NSString *key = [userInfo objectForKey:@"key"];
    selectedPost = [[PostDBSingleton singleton] postForKey:key];
    if (selectedPost) {
        [self showSelectedPost];
    }
}

@end
