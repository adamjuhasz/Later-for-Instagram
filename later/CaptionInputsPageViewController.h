//
//  CaptionInputsPageViewController.h
//  later
//
//  Created by Adam Juhasz on 4/19/15.
//  Copyright (c) 2015 Adam Juhasz. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol inputsPageDelegate <NSObject>
@required

- (void)inputPageChangeToPageNumber:(NSInteger)pageNumber;

@end

@interface CaptionInputsPageViewController : UIPageViewController <UIPageViewControllerDataSource, UIPageViewControllerDelegate>

@property IBOutletCollection(UIViewController) NSArray* pages;
@property (weak) id <inputsPageDelegate> controllerDelegate;

- (void)swithToPage:(NSInteger)pageNumber;

@end
