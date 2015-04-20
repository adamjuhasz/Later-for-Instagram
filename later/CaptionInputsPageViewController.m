//
//  CaptionInputsPageViewController.m
//  later
//
//  Created by Adam Juhasz on 4/19/15.
//  Copyright (c) 2015 Adam Juhasz. All rights reserved.
//

#import "CaptionInputsPageViewController.h"
#

@interface CaptionInputsPageViewController ()

@end

@implementation CaptionInputsPageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.dataSource = self;
}

- (void)viewDidAppear:(BOOL)animated
{
    [self setViewControllers:@[self.pages[1]] direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Page View Controller Data Source

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController
{
    NSUInteger index = [self.pages indexOfObject:viewController];
    
    if ((index == 0) || (index == NSNotFound)) {
        return nil;
    }
    
    index--;
    return self.pages[index];
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController
{
    NSUInteger index = [self.pages indexOfObject:viewController];
    
    if (index == NSNotFound) {
        return nil;
    }
    
    index++;
    if (index == [self.pages count]) {
        return nil;
    }
    return self.pages[index];
}

- (void)switchToPage:(NSInteger)pageNumber
{
    [self setViewControllers:@[self.pages[pageNumber]] direction:UIPageViewControllerNavigationDirectionForward animated:YES completion:nil];
}

@end
