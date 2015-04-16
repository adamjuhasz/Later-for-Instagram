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
}
@end

@implementation SchedulesPostsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if ([[PhotoManager sharedManager] authorized] == NO) {
        
    }
    
    // Do any additional setup after loading the view.
    viewsInScrollView = [NSMutableArray array];
    scheduledPosts = [[PostDBSingleton singleton] allposts];
    
    self.scheduledScroller.contentInset = UIEdgeInsetsMake(64, 0, 0, 0);
    self.scheduledScroller.scrollIndicatorInsets = self.scheduledScroller.contentInset;
    
    shroud = [[UIView alloc] initWithFrame:CGRectMake(0, addButton.frame.size.height, self.scheduledScroller.bounds.size.width, self.scheduledScroller.bounds.size.height)];
    shroud.backgroundColor = [UIColor blackColor];
    [self.scheduledScroller addSubview:shroud];
    
    self.collectionView.contentInset = self.scheduledScroller.contentInset;
    self.collectionView.scrollIndicatorInsets = self.scheduledScroller.contentInset;
    //self.collectionView.alpha = 0.0;
    
    [self reloadScrollView];
    [self.collectionView reloadData];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(photosUpdated) name:@"PhotoManagerLoaded" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newPostWasAdded) name:kPostDBUpatedNotification object:nil];
    
    captionController = [self.storyboard instantiateViewControllerWithIdentifier:@"captionViewController"];
    
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
}

- (void)viewDidAppear:(BOOL)animated
{
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    if (appDelegate.notification) {
        NSString *postKey = [appDelegate.notification.userInfo objectForKey:@"key"];
        NSString *action = appDelegate.notificationAction;
        NSLog(@"user wants to %@ a specific notification (%@)", action, postKey);
        
        appDelegate.notification = nil;
        appDelegate.notificationAction = nil;
        
        if([appDelegate.notificationAction isEqualToString:@"send"]) {
            [self sendPostToInstragramWithKey:postKey];
        }
    }
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
    scheduledPostModel *thePost = scheduledPosts[recognizer.view.tag];
    selectedPost = thePost;
    
    selectedPostShroud = [[UIView alloc] initWithFrame:self.view.bounds];
    selectedPostShroud.backgroundColor = [UIColor clearColor];
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideSelectedPost)];
    [selectedPostShroud addGestureRecognizer:tap];
    [self.view insertSubview:selectedPostShroud belowSubview:self.selectedPostView];
    
    self.SelectedPostImageView.image = selectedPost.postImage;
    
    self.selectedPostView.hidden = NO;
    [UIView animateWithDuration:0.4
                     animations:^{
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
                     }
                     completion:^(BOOL finished) {
                         self.selectedPostView.hidden = YES;
                     }];
    
    [selectedPostShroud removeFromSuperview];
    selectedPostShroud = nil;
}

- (IBAction)sendSelectedPostToInstagram
{
    [self sendPostToInstragramWithKey:selectedPost.key];
    

}

- (void)sendPostToInstragramWithKey:(NSString*)postKey
{
    NSArray *allposts = [[PostDBSingleton singleton] allposts];
    scheduledPostModel *selectedPost;
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
        NSLog(@"ready to load instagram");
        
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
    
    [[PostDBSingleton singleton] removePost:postThatIsBeingPosted];
    postThatIsBeingPosted = nil;
}

- (void)photosUpdated
{
    [self.collectionView reloadData];
}

- (void)reloadScrollView
{
    scheduledPosts = [[PostDBSingleton singleton] allposts];
    
    for (UIView *subview in viewsInScrollView) {
        [subview removeFromSuperview];
    }
    [viewsInScrollView removeAllObjects];
    
    CGFloat border = 4;
    CGFloat columns = 2;
    CGFloat width = (self.scheduledScroller.bounds.size.width - border)/columns;
    CGRect mainRect = CGRectMake(0, border, width, width);
    CGRect currrentFrame;
    for (int i=0; i<scheduledPosts.count; i++) {
        int column = i % 2;
        int row = floor(i / 2.0);
        
        scheduledPostModel *post = scheduledPosts[i];
        
        NSTimeInterval secondsToGo = [post.postTime timeIntervalSinceNow];
        
        // Get the system calendar
        NSCalendar *sysCalendar = [NSCalendar currentCalendar];
        
        // Create the NSDates
        NSDate *date1 = [[NSDate alloc] init];
        NSDate *date2 = [[NSDate alloc] initWithTimeInterval:secondsToGo sinceDate:date1];
        
        // Get conversion to months, days, hours, minutes
        unsigned int unitFlags = NSCalendarUnitSecond |  NSCalendarUnitMinute  | NSCalendarUnitHour | NSCalendarUnitDay | NSCalendarUnitMonth;
        
        NSDateComponents *breakdownInfo = [sysCalendar components:unitFlags fromDate:date1  toDate:date2  options:0];
        NSLog(@"Break down: %ld sec : %ld min : %ld hours : %ld days : %ld months", [breakdownInfo second], [breakdownInfo minute], [breakdownInfo hour], [breakdownInfo day], [breakdownInfo month]);
        
        currrentFrame = CGRectOffset(mainRect, column*(mainRect.size.width+border), row*(mainRect.size.height+border));
        UIView *newImage =  [[UIView alloc] initWithFrame:currrentFrame];
        newImage.backgroundColor = [UIColor darkGrayColor];
        //newImage.layer.cornerRadius = 10.0;
        newImage.clipsToBounds = YES;
        
        CGRect imageRect = CGRectMake(0, 0, currrentFrame.size.width, currrentFrame.size.width);
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:imageRect];
        imageView.image = post.postImage;
        [newImage addSubview:imageView];
        
        CGRect timeLabelRect = CGRectMake(10, imageRect.origin.y + imageRect.size.height + 8, imageRect.size.width - 5, 15);
        UILabel *timeLabel = [[UILabel alloc] initWithFrame:timeLabelRect];
        timeLabel.text = [NSString stringWithFormat:@"%ld mins left", ABS([breakdownInfo minute])];
        timeLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:18];
        timeLabel.textColor = [UIColor whiteColor];
        [newImage addSubview:timeLabel];
        
        CGRect captionLabelRect = CGRectMake(10, timeLabelRect.origin.y + timeLabelRect.size.height + 5, imageRect.size.width - 5, 17);
        UILabel *captionLabel = [[UILabel alloc] initWithFrame:captionLabelRect];
        captionLabel.text = post.postCaption;
        captionLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:12];
        captionLabel.textColor = [UIColor whiteColor];
        [newImage addSubview:captionLabel];
        
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
    
    if (velocity.y < -1.0 && scrollView.contentOffset.y < 0) {
        *targetContentOffset = CGPointZero;
        [self hideScrollview];
    }
}

- (void)authorizePhotos
{
    if ([[PhotoManager sharedManager] authorized] == NO) {
        [[PhotoManager sharedManager] getAlbumNamesWhenDone:^{
            NSLog(@"%@", [[PhotoManager sharedManager] albumNames]);
            NSLog(@"Camera Roll: %@", [[PhotoManager sharedManager] cameraRollAlbumName]);
            NSRange cacheRange = {0, 50};
            [[PhotoManager sharedManager] getLibraryImagesForAlbum:[[PhotoManager sharedManager] cameraRollAlbumName]
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
    animating = YES;
    self.scheduledScroller.userInteractionEnabled = NO;
    
    [self authorizePhotos];
    
    [UIView animateWithDuration:0.2
                          delay:0.0
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         CGRect goneFrame = self.scheduledScroller.frame;
                         goneFrame.origin.y = self.view.bounds.size.height;
                         self.scheduledScroller.frame = goneFrame;
                         
                         self.collectionView.alpha = 1.0;
                         self.collectionView.contentInset = UIEdgeInsetsMake(64, 0, 0, 0);
                         self.collectionView.scrollIndicatorInsets = self.collectionView.contentInset;
                         self.collectionView.contentOffset = CGPointMake(0, self.collectionView.contentInset.top*-1);
                         
                         self.collectionView.transform = CGAffineTransformIdentity;
                         
                         for (UIView *aView in self.scheduleMenuViews) {
                             aView.alpha = 0.0;
                         }
                         for (UIView *aView in self.photoPickerMenuViews) {
                             aView.alpha = 1.0;
                         }
                     }
                     completion:^(BOOL finished) {
                         self.scheduledScroller.hidden = YES;
                     }];

}

- (IBAction)resetScrollview
{
    self.scheduledScroller.userInteractionEnabled = YES;
    self.scheduledScroller.hidden = NO;
    
    [UIView animateWithDuration:0.2
                          delay:0.0
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         CGRect goneFrame = self.scheduledScroller.frame;
                         goneFrame.origin.y = 0;
                         self.scheduledScroller.frame = goneFrame;
                         
                         self.scheduledScroller.contentOffset = CGPointMake(0, -64);
                         
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
                     }];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView
     numberOfItemsInSection:(NSInteger)section
{
    PhotoManager *shared = [PhotoManager sharedManager];
    NSInteger count = [shared countForAlbum:shared.cameraRollAlbumName];
    if (count <= 0) {
        return 30;
    }
    return count;
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                 cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    PhotoTableViewCell *myCell = [collectionView
                           dequeueReusableCellWithReuseIdentifier:@"PhotoCell"
                           forIndexPath:indexPath];
    
    UIImage *image;
    long row = [indexPath row];
    
    PhotoManager *shared =  [PhotoManager sharedManager];
    image =  [shared imageIn:shared.cameraRollAlbumName atIndex:row];
    
    myCell.photoView.image = image;
    
    return myCell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"CLICK!");
    UIImage *thumbnail = [[PhotoManager sharedManager] imageIn:[[PhotoManager sharedManager] cameraRollAlbumName] atIndex:indexPath.row];
    [captionController setThumbnail:thumbnail];
    [self.navigationController pushViewController:captionController animated:YES];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [[PhotoManager sharedManager] fullsizeImageIn:[[PhotoManager sharedManager] cameraRollAlbumName]
                                              atIndex:indexPath.row
                                      completionBlock:^(UIImage *image) {
                                          NSLog(@"sent caption view the full size image");
                                          [captionController setPhoto:image];
                                      }];

    });
}

- (void)newPostWasAdded
{
    [self reloadScrollView];
    [self resetScrollview];
    [self.navigationController popToRootViewControllerAnimated:YES];
}

@end
