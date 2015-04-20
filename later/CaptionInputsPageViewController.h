//
//  CaptionInputsPageViewController.h
//  later
//
//  Created by Adam Juhasz on 4/19/15.
//  Copyright (c) 2015 Adam Juhasz. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CaptionInputsPageViewController : UIPageViewController <UIPageViewControllerDataSource>

@property IBOutletCollection(UIViewController) NSArray* pages;

@end
