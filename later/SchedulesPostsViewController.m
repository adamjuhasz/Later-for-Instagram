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

@interface SchedulesPostsViewController ()
{
    NSMutableArray *viewsInScrollView;
    NSArray *scheduledPosts;
    UIView *addButton;
    UIView *shroud;
    CommentEntryViewController *captionController;
    UIDocumentInteractionController *document;
    scheduledPostModel *postThatIsBeingPosted;
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
    
    self.scheduledScroller.contentInset = UIEdgeInsetsMake(20, 0, 0, 0);
    self.scheduledScroller.scrollIndicatorInsets = self.scheduledScroller.contentInset;
    
    addButton = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.scheduledScroller.bounds.size.width, 44)];
    addButton.backgroundColor = [UIColor darkGrayColor];
    self.scheduledScroller.contentSize = CGSizeMake(self.scheduledScroller.bounds.size.width, addButton.frame.size.height);
    [self.scheduledScroller addSubview:addButton];
    
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

- (void)sendPostToInstragramWithKey:(NSString*)postKey
{
    NSArray *allposts = [[PostDBSingleton singleton] allposts];
    scheduledPostModel *selectedPost;
    for (scheduledPostModel *post in allposts) {
        if ([postKey isEqualToString:post.key]) {
            selectedPost = post;
        }
    }
    
    if (selectedPost) {
        document = [UIDocumentInteractionController interactionControllerWithURL:[NSURL fileURLWithPath:selectedPost.postImageLocation isDirectory:NO]];
        document.UTI = @"com.instagram.exclusivegram";
        document.delegate = self;
        document.annotation = [NSDictionary dictionaryWithObject:selectedPost.postCaption forKey:@"InstagramCaption"];
        NSLog(@"ready to load instagram");
        
        BOOL success = [document presentOptionsMenuFromRect:CGRectMake(1, 1, 1, 1) inView:self.navigationController.view animated:YES];
        if (success) {
            postThatIsBeingPosted = selectedPost;
        }
    }
}

- (void)documentInteractionController:(UIDocumentInteractionController *)controller willBeginSendingToApplication:(NSString *)application
{
    NSLog(@"sedning");
}

- (void)documentInteractionController:(UIDocumentInteractionController *)controller didEndSendingToApplication:(NSString *)application
{
    NSLog(@"end sending");
    document = nil;
    [[PostDBSingleton singleton] removePost:postThatIsBeingPosted];
    postThatIsBeingPosted = nil;
}


- (void)photosUpdated
{
    [self.collectionView reloadData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)reloadScrollView
{
    scheduledPosts = [[PostDBSingleton singleton] allposts];
    
    for (UIView *subview in viewsInScrollView) {
        [subview removeFromSuperview];
    }
    [viewsInScrollView removeAllObjects];
    
    CGRect mainRect = CGRectMake(0, 45, 187, 187);
    CGRect currrentFrame;
    for (int i=0; i<scheduledPosts.count; i++) {
        int column = i % 2;
        int row = floor(i / 2.0);
        
        scheduledPostModel *post = scheduledPosts[i];
        
        currrentFrame = CGRectOffset(mainRect, column*(mainRect.size.width+1), row*(mainRect.size.width+1));
        UIView *newImage =  [[UIView alloc] initWithFrame:currrentFrame];
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:newImage.bounds];
        imageView.image = post.postImage;
        [newImage addSubview:imageView];
        newImage.backgroundColor = [UIColor darkGrayColor];
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(postWasTapped:)];
        [newImage addGestureRecognizer:tap];
        newImage.tag = i;
        
        [self.scheduledScroller insertSubview:newImage aboveSubview:shroud];
        [viewsInScrollView addObject:newImage];
    }
    
    self.scheduledScroller.contentSize = CGSizeMake(self.scheduledScroller.bounds.size.width,
                                                    MAX(currrentFrame.origin.y + currrentFrame.size.height,
                                                        0));
}
                                       
- (void)postWasTapped:(UIGestureRecognizer*)recognizer
{
    NSLog(@"tapped");
    scheduledPostModel *thePost = scheduledPosts[recognizer.view.tag];
    [self sendPostToInstragramWithKey:thePost.key];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (scrollView != self.scheduledScroller) {
        return;
    }
    
    if (scrollView.contentOffset.y < -1 * scrollView.contentInset.top && animating == NO) {
        CGFloat expansionSpace = scrollView.contentOffset.y - scrollView.contentInset.top*-1;
        
        CGRect addButtonFrame = addButton.frame;
        addButtonFrame.origin.y = expansionSpace;
        addButtonFrame.size.height = 44 + ABS(expansionSpace);
        addButton.frame = addButtonFrame;
        
        CGFloat alphaPercent = 1.0 - ABS(expansionSpace/88);
        addButton.alpha = alphaPercent;
        
        CGFloat collectionAlpha = MAX((1.0 - alphaPercent) * 0.01, 0.1);
        self.collectionView.alpha = collectionAlpha;
        //NSLog(@"alphaPercent: %f", alphaPercent);
        //self.collectionView.transform = CGAffineTransformMakeScale(1-alphaPercent, 1-alphaPercent);
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

- (IBAction)hideScrollview
{
    animating = YES;
    self.scheduledScroller.userInteractionEnabled = NO;
    
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
    
    CGPoint currentOffset = self.scheduledScroller.contentOffset;
    CGRect currentFrame = self.scheduledScroller.frame;
    
    currentFrame.origin.y = currentOffset.y * -1 + self.scheduledScroller.contentInset.top;
    self.scheduledScroller.frame = currentFrame;
    self.scheduledScroller.contentOffset = CGPointZero;
    
    [UIView animateWithDuration:0.2
                          delay:0.0
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         CGRect goneFrame = self.scheduledScroller.frame;
                         goneFrame.origin.y = self.view.bounds.size.height;
                         self.scheduledScroller.frame = goneFrame;
                         
                         self.menuBar.alpha = 1.0;
                         
                         self.collectionView.alpha = 1.0;
                         self.collectionView.contentInset = UIEdgeInsetsMake(64, 0, 0, 0);
                         self.collectionView.scrollIndicatorInsets = self.collectionView.contentInset;
                         self.collectionView.contentOffset = CGPointMake(0, self.collectionView.contentInset.top*-1);
                     }
                     completion:^(BOOL finished) {
                         self.scheduledScroller.hidden = YES;
                     }];

}

- (IBAction)resetScrollview
{
    animating = NO;
    addButton.alpha = 1.0;
    addButton.frame = CGRectMake(0, 0, self.scheduledScroller.bounds.size.width, 44);
    
    self.scheduledScroller.userInteractionEnabled = YES;
    self.scheduledScroller.hidden = NO;
    
    [UIView animateWithDuration:0.2
                          delay:0.0
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         CGRect goneFrame = self.scheduledScroller.frame;
                         goneFrame.origin.y = 0;
                         self.scheduledScroller.frame = goneFrame;
                         
                         self.menuBar.alpha = 0.0;
                         
                         self.scheduledScroller.contentOffset = CGPointMake(0, -20);
                         
                         self.collectionView.alpha = 0.0;
                         self.collectionView.contentInset = self.scheduledScroller.contentInset;
                         self.collectionView.scrollIndicatorInsets = self.scheduledScroller.contentInset;
                         self.collectionView.contentOffset = CGPointZero;
                     }
                     completion:^(BOOL finished) {
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
