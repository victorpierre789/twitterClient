//
//  RWBasicCell.h
//  DeviantArtBrowser
//
//  Created by Joshua Greene on 11/23/14.
//  Copyright (c) 2014 Razeware, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "STTweetLabel.h"

#import "RWLabel.h"

@interface RWBasicCell : UITableViewCell
@property (nonatomic, weak) IBOutlet RWLabel *titleLabel;
@property (nonatomic, weak) IBOutlet RWLabel *date;
@property (nonatomic, weak) IBOutlet STTweetLabel *subtitleLabel;
@property (nonatomic, weak) IBOutlet UIImageView *profileImage;
@end
