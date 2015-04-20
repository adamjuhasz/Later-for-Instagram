//
//  TableViewController.h
//  later
//
//  Created by Adam Juhasz on 4/19/15.
//  Copyright (c) 2015 Adam Juhasz. All rights reserved.
//

#import <UIKit/UIKit.h>



@protocol TableViewControllerDelegate <NSObject>
@required
- (void)didSelectHashtag:(NSString*)hashtag atIndexPath:(NSIndexPath*)indexPath;

@end

@interface TableViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property IBOutlet UITableView *hashtagTable;

- (IBAction)clearTable;
- (void)searchForTag:(NSString*)hashtag;

@property id <TableViewControllerDelegate> delegate;

@end
