//
//  RWTableViewController.h
//  DeviantArtBrowser
//
//  Created by Joshua Greene on 4/1/14.
//  Copyright (c) 2014 Razeware, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RSSParser;

@interface RWFeedViewController : UIViewController <UITextFieldDelegate>

@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (strong, nonatomic) IBOutlet UIImageView *imageView;
@property (strong, nonatomic) IBOutlet UITextField *textfield;

@property (strong, nonatomic) IBOutlet UIButton *tweets;
@property (strong, nonatomic) IBOutlet UIButton *photos;
@property (strong, nonatomic) IBOutlet UIButton *abonnes;
@property (strong, nonatomic) IBOutlet UIButton *abonnements;

@property (strong, nonatomic) IBOutlet UIButton *button;

@property (strong, nonatomic) IBOutlet UIButton *button2;

@property (strong, nonatomic) IBOutlet UIButton *button3;

@end
