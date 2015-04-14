//
//  SchedulesPostsViewController.m
//  later
//
//  Created by Adam Juhasz on 4/13/15.
//  Copyright (c) 2015 Adam Juhasz. All rights reserved.
//

#import "SchedulesPostsViewController.h"
#import <CSStickyHeaderFlowLayout/CSStickyHeaderFlowLayout.h>

@interface SchedulesPostsViewController ()
{
    UIView *backgroundCamera;
    UIView *backgroundShroud;
}
@end

@implementation SchedulesPostsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self.collectionView setContentInset:UIEdgeInsetsMake(20, 0, 0, 0)];
    
    CSStickyHeaderFlowLayout *layout = (id)self.collectionView.collectionViewLayout;
    layout.parallaxHeaderReferenceSize = CGSizeMake(self.view.frame.size.width, 44+20);
    layout.itemSize = CGSizeMake(self.view.frame.size.width / 2.0 - 1, self.view.frame.size.width / 2.0 - 1);
    
    backgroundCamera = [[UIView alloc] initWithFrame:self.collectionView.bounds];
    backgroundShroud = [[UIView alloc] initWithFrame:self.collectionView.bounds];
    [backgroundCamera addSubview:backgroundShroud];
    
    backgroundShroud.backgroundColor = self.collectionView.backgroundColor;
    backgroundCamera.backgroundColor = [UIColor redColor];
    
    self.collectionView.backgroundView = backgroundCamera;
    backgroundShroud.frame = CGRectOffset(backgroundShroud.frame, 0, 20);
    backgroundShroud.frame = CGRectOffset(backgroundShroud.frame, 0, layout.parallaxHeaderReferenceSize.height+20);
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hideScheduled) name:@"hideScheduled" object:nil];
    
    [self.collectionView addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew context:NULL];
    
    [self.collectionView registerNib:[UINib nibWithNibName:@"NewHeader" bundle:nil]
          forSupplementaryViewOfKind:CSStickyHeaderParallaxHeader
                 withReuseIdentifier:@"header"];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return 10;
}

- (UICollectionViewCell*)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"ScheduleCell" forIndexPath:indexPath];
    
    return cell;
    
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    if ([kind isEqualToString:CSStickyHeaderParallaxHeader]) {
        UICollectionReusableView *cell = [collectionView dequeueReusableSupplementaryViewOfKind:kind
                                                                            withReuseIdentifier:@"header"
                                                                                   forIndexPath:indexPath];
        
        return cell;
    }
    
    return nil;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"contentOffset"]) {
        backgroundShroud.frame = CGRectMake(0, self.collectionView.contentOffset.y*-1+44+20, backgroundShroud.frame.size.width, backgroundShroud.frame.size.height);
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)hideScheduled {
    CGPoint oldOffset = self.collectionView.contentOffset;
    NSLog(@"%@", NSStringFromCGPoint(oldOffset));
    [self.collectionView setContentOffset:CGPointZero animated:NO];
    self.collectionView.userInteractionEnabled = NO;
    self.collectionView.frame = CGRectMake(0, -1 * oldOffset.y - 20, self.collectionView.bounds.size.width, self.collectionView.bounds.size.height);
    
}

@end
