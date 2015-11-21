//
//  RWTableViewController.m
//  DeviantArtBrowser
//
//  Created by Joshua Greene on 4/1/14.
//  Copyright (c) 2014 Razeware, LLC. All rights reserved.
//

#import "RWFeedViewController.h"

#import "TWBSocialHelper.h"
#import "UIImageView+WebCache.h"
#import "JTSImageViewController.h"
#import "JTSImageInfo.h"
#import "UIColor+HexString.h"
#import "STTweetLabel.h"

#import "RWBasicCell.h"
#import "RWImageCell.h"

#define kCouleurRouge 0
#define kCouleurBleu 1
#define kCouleurVert 2
#define kCouleurJaune 3

static NSString * const RWBasicCellIdentifier = @"RWBasicCell";
static NSString * const RWImageCellIdentifier = @"RWImageCell";

@interface RWFeedViewController ()

@property (nonatomic) TWBSocialHelper *localInstance;

@property (strong, nonatomic) NSArray *array;

@property (nonatomic,strong) UIRefreshControl *refreshControl;

@end

@implementation RWFeedViewController

#pragma mark - View Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _localInstance = [TWBSocialHelper sharedHelper];
    [self requestAccessToTwitter];
    
    [NSTimer scheduledTimerWithTimeInterval:0.5
                                     target:self
                                   selector:@selector(twitterTimeline)
                                   userInfo:nil
                                    repeats:NO];
    
    [NSTimer scheduledTimerWithTimeInterval:1
                                     target:self
                                   selector:@selector(getInfo)
                                   userInfo:nil
                                    repeats:NO];
    
    self.view.backgroundColor = [UIColor colorWithHexString:@"#ffffff"];
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(refreshInvoked:forState:) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:self.refreshControl];
    
    self.refreshControl.tintColor = [UIColor whiteColor];
    
    self.button.layer.cornerRadius = 17.5;
    self.button.layer.masksToBounds = YES;
    
    /*
    self.tableView.layer.cornerRadius = 10;
    self.tableView.layer.masksToBounds = YES;
     */
    
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    self.view.backgroundColor = [UIColor colorWithHexString:@"#17293a"];
}

-(void)viewWillAppear:(BOOL)animated
{
    //[self downloadTimeline];
    //[self.tableView reloadData];
    NSLog(@"%@", _localInstance.twitterAccount);
}

#pragma mark - Twitter Access
-(void)requestAccessToTwitter
{
    
    _localInstance = [TWBSocialHelper sharedHelper];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        [_localInstance requestAccessToTwitterAccounts];
    });
}

- (IBAction)composeTweet:(id)sender {
    SLComposeViewController *controllerSLC = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeTwitter];
    [controllerSLC setInitialText:@""];
    [self presentViewController:controllerSLC animated:YES completion:Nil];
}

- (void) getInfo
{
    // Request access to the Twitter accounts
    
    ACAccountStore *accountStore = [[ACAccountStore alloc] init];
    ACAccountType *accountType = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    
    [accountStore requestAccessToAccountsWithType:accountType options:nil completion:^(BOOL granted, NSError *error){
        if (granted) {
            
            NSArray *accounts = [accountStore accountsWithAccountType:accountType];
            
            // Check if the users has setup at least one Twitter account
            
            if (accounts.count > 0)
            {
                ACAccount *twitterAccount = [accounts objectAtIndex:0];
                
                // Creating a request to get the info about a user on Twitter
                
                SLRequest *twitterInfoRequest = [SLRequest requestForServiceType:SLServiceTypeTwitter requestMethod:SLRequestMethodGET URL:[NSURL URLWithString:@"https://api.twitter.com/1.1/users/show.json"] parameters:[NSDictionary dictionaryWithObject:twitterAccount.username forKey:@"screen_name"]];
                [twitterInfoRequest setAccount:twitterAccount];
                
                // Making the request
                
                [twitterInfoRequest performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        
                        // Check if we reached the reate limit
                        
                        if ([urlResponse statusCode] == 429) {
                            NSLog(@"Rate limit reached");
                            return;
                        }
                        
                        // Check if there was an error
                        
                        if (error) {
                            NSLog(@"Error: %@", error.localizedDescription);
                            return;
                        }
                        
                        // Check if there is some response data
                        
                        if (responseData) {
                            
                            NSError *error = nil;
                            NSArray *TWData = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingMutableLeaves error:&error];
                            
                            NSString *screen_name = [(NSDictionary *)TWData objectForKey:@"screen_name"];
                            
                            NSLog(@"Le log : %@", [NSString stringWithFormat:@"@%@",screen_name]);
                            
                            NSString *profileImageStringURL = [(NSDictionary *)TWData objectForKey:@"profile_image_url_https"];
                            
                            profileImageStringURL = [profileImageStringURL stringByReplacingOccurrencesOfString:@"_normal" withString:@""];
                            [self getProfileImageForURLString:profileImageStringURL];
                        }
                    });
                }];
            }
        } else {
            NSLog(@"No access granted");
        }
    }];
}

- (void) getProfileImageForURLString:(NSString *)urlString;
{
    NSURL *url = [NSURL URLWithString:urlString];
    NSData *data = [NSData dataWithContentsOfURL:url];
    UIImage *btnImage = [UIImage imageWithData:data];
    [self.button setImage:btnImage forState:UIControlStateNormal];
}

- (void)twitterTimeline {
    
    NSURL *timelineURL         = [NSURL URLWithString:@"https://api.twitter.com/1.1/statuses/home_timeline.json"];
    
    NSDictionary *params       = @{@"count": @"200"};
    
    // Create a request
    SLRequest *getUserTimeline = [SLRequest requestForServiceType:SLServiceTypeTwitter
                                                    requestMethod:SLRequestMethodGET
                                                              URL:timelineURL
                                                       parameters:params];
    
    // Set the account for the request
    [getUserTimeline setAccount:_localInstance.twitterAccount];
    
    NSLog(@"%@", _localInstance.twitterAccount);
    
    
    // Perform the request
    [getUserTimeline performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
        _array = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingAllowFragments error:nil];
        
        NSLog(@"%@", _array);
        
        if (self.array.count != 0) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                [self.tableView reloadData]; // Here we tell the table view to reload the data it just recieved.
                
            });
        }
    }];
    
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_array count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([self hasImageAtIndexPath:indexPath]) {
        RWImageCell *cell = [self.tableView dequeueReusableCellWithIdentifier:RWImageCellIdentifier forIndexPath:indexPath];
        // Remove seperator inset
        if ([cell respondsToSelector:@selector(setSeparatorInset:)]) {
            [cell setSeparatorInset:UIEdgeInsetsZero];
        }
        
        // Prevent the cell from inheriting the Table View's margin settings
        if ([cell respondsToSelector:@selector(setPreservesSuperviewLayoutMargins:)]) {
            [cell setPreservesSuperviewLayoutMargins:NO];
        }
        
        // Explictly set your cell's layout margins
        if ([cell respondsToSelector:@selector(setLayoutMargins:)]) {
            [cell setLayoutMargins:UIEdgeInsetsZero];
        }
        
        [self configureImageCell:cell atIndexPath:indexPath];
        
        return cell;
    } else {
        RWBasicCell *cell = [self.tableView dequeueReusableCellWithIdentifier:RWBasicCellIdentifier forIndexPath:indexPath];
        // Remove seperator inset
        if ([cell respondsToSelector:@selector(setSeparatorInset:)]) {
            [cell setSeparatorInset:UIEdgeInsetsZero];
        }
        
        // Prevent the cell from inheriting the Table View's margin settings
        if ([cell respondsToSelector:@selector(setPreservesSuperviewLayoutMargins:)]) {
            [cell setPreservesSuperviewLayoutMargins:NO];
        }
        
        // Explictly set your cell's layout margins
        if ([cell respondsToSelector:@selector(setLayoutMargins:)]) {
            [cell setLayoutMargins:UIEdgeInsetsZero];
        }
        [self configureBasicCell:cell atIndexPath:indexPath];
        
        return cell;
    }
}

- (BOOL)hasImageAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *tweet = _array[indexPath.row];
    
    NSString *imageHD2Array = [tweet valueForKeyPath:@"entities.media.media_url"];
    
    return imageHD2Array != nil;
}

- (void)configureImageCell:(RWImageCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *tweet = _array[indexPath.row];
    
    //NSLog(@"%@", tweet);
    
    cell.titleLabel.text = [NSString stringWithFormat:@"%@ @%@", [[tweet objectForKey:@"user"] valueForKey:@"name"], [[tweet objectForKey:@"user"] valueForKey:@"screen_name"]];
    
    cell.subtitleLabel.text = [tweet valueForKey:@"text"];
    
    cell.subtitleLabel.detectionBlock = ^(STTweetHotWord hotWord, NSString *string, NSString *protocol, NSRange range) {
        
        NSArray *hotWords = @[@"Handle", @"Hashtag", @"Link"];
        NSLog(@"%@", [NSString stringWithFormat:@"%@ [%d,%d]: %@%@", hotWords[hotWord], (int)range.location, (int)range.length, string, (protocol != nil) ? [NSString stringWithFormat:@" *%@*", protocol] : @""]);
    };
    
    NSString *dateString = [tweet valueForKey:@"created_at"];
    
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"]];
    [df setFormatterBehavior:NSDateFormatterBehavior10_4];
    [df setDateFormat:@"EEE MMM dd HH:mm:ss Z yyyy"];
    NSDate *convertedDate = [df dateFromString:dateString];
    NSDate *todayDate = [NSDate date];
    double ti = [convertedDate timeIntervalSinceDate:todayDate];
    ti = ti * -1;
    if(ti < 1) {
        dateString = @"jamais";
        NSLog(@"%@", dateString);
    } else 	if (ti < 60) {
        int diff = round(ti < 60);
        dateString = [NSString stringWithFormat:@"%dsec",diff];
        NSLog(@"%@", dateString);
    } else if (ti < 3600) {
        int diff = round(ti / 60);
        dateString = [NSString stringWithFormat:@"%dm",diff];
        NSLog(@"%@", dateString);
    } else if (ti < 86400) {
        int diff = round(ti / 60 / 60);
        dateString = [NSString stringWithFormat:@"%dh",diff];
        NSLog(@"%@", dateString);
    } else if (ti < 2629743) {
        int diff = round(ti / 60 / 60 / 24);
        dateString = [NSString stringWithFormat:@"%dj",diff];
        NSLog(@"%@", dateString);
    } else {
        dateString =  @"never";
        NSLog(@"%@", dateString);
    }
    
    cell.date.text = dateString;
    
    NSString *imageHD = [[tweet objectForKey:@"user"] valueForKey:@"profile_image_url"];
    
    NSString *stringWithoutSpaces = [imageHD
                                     stringByReplacingOccurrencesOfString:@"_normal" withString:@""];
    
    NSLog(@"%@", stringWithoutSpaces);
    
    cell.profileImage.layer.cornerRadius = 25.5;
    cell.profileImage.layer.masksToBounds = YES;
    
    cell.profileImage.layer.borderWidth = 0.5;
    cell.profileImage.clipsToBounds = YES;
    cell.profileImage.layer.borderColor = [UIColor whiteColor].CGColor;
        
    /*
         int randomNumber = arc4random() %4;
         
         switch (randomNumber) {
             case kCouleurRouge:
                 NSLog(@"On set la couleur rouge");
                 cell.profileImage.layer.borderColor = [UIColor blueColor].CGColor;
                 break;
             case kCouleurBleu:
                 NSLog(@"On set la couleur bleu");
                 cell.profileImage.layer.borderColor = [UIColor greenColor].CGColor;
                 break;
             case kCouleurVert:
                 NSLog(@"On set la couleur vert");
                 cell.profileImage.layer.borderColor = [UIColor blackColor].CGColor;
                 break;
             case kCouleurJaune:
                 NSLog(@"On set la couleur jaune");
                 cell.profileImage.layer.borderColor = [UIColor lightGrayColor].CGColor;
                 break;
             default:
                 NSLog(@"Erreur");
                 break;
         }
     */
    
    //cell.customImageView.layer.cornerRadius = 5;
    //cell.customImageView.layer.masksToBounds = YES;
    
    SDWebImageManager *manager = [SDWebImageManager sharedManager];
    [manager downloadImageWithURL:[NSURL URLWithString:stringWithoutSpaces]
                          options:0
                         progress:^(NSInteger receivedSize, NSInteger expectedSize) {
                             // progression tracking code
                         }
                        completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
                            if (image) {
                                // do something with image
                                cell.profileImage.image = image;
                                [cell.profileImage setClipsToBounds:YES];
                            }
                        }];
    
    NSArray *stringImage = [tweet valueForKeyPath:@"entities.media.media_url"];
    
    NSString *lienComplet = [NSString stringWithFormat:@"%@:small", stringImage[0]];
    
    NSLog(@"%@", lienComplet);
    
    if ([stringImage count] == 0) {
        
    } else {
        SDWebImageManager *manager = [SDWebImageManager sharedManager];
        [manager downloadImageWithURL:[NSURL URLWithString:lienComplet]
                              options:0
                             progress:^(NSInteger receivedSize, NSInteger expectedSize) {
                                 // progression tracking code
                             }
                            completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
                                if (image) {
                                    // do something with image
                                    cell.customImageView.image = image;
                                    [cell.customImageView setClipsToBounds:YES];
                                    
                                    cell.customImageView.userInteractionEnabled = YES;
                                    cell.customImageView.tag = indexPath.row;
                                    
                                    UITapGestureRecognizer *tapped = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(myFunction:)];
                                    tapped.numberOfTapsRequired = 1;
                                    [cell.customImageView addGestureRecognizer:tapped];
                                }
                            }];
        
    }
}

- (void)myFunction:(UITapGestureRecognizer *)recognizer
{
    CGPoint swipeLocation = [recognizer locationInView:self.tableView];
    NSIndexPath *swipedIndexPath = [self.tableView indexPathForRowAtPoint:swipeLocation];
    RWImageCell *swipedCell = [self.tableView cellForRowAtIndexPath:swipedIndexPath];
    NSDictionary *tweet = _array[swipedIndexPath.row];
    NSArray *imageHD2Array = [tweet valueForKeyPath:@"entities.media.media_url"];
    NSLog(@"%@", imageHD2Array);
    NSURL *url = [NSURL URLWithString:imageHD2Array[0]];
    NSData *data = [NSData dataWithContentsOfURL:url];
    
    // Create image info
    JTSImageInfo *imageInfo = [[JTSImageInfo alloc] init];
    imageInfo.image = [UIImage imageWithData:data];
    
    // Setup view controller
    JTSImageViewController *imageViewer = [[JTSImageViewController alloc]
                                           initWithImageInfo:imageInfo
                                           mode:JTSImageViewControllerMode_Image
                                           backgroundStyle:JTSImageViewControllerBackgroundOption_Blurred];
    
    // Present the view controller.
    [imageViewer showFromViewController:self transition:JTSImageViewControllerTransition_FromOriginalPosition];
}

- (void)configureBasicCell:(RWBasicCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *tweet = _array[indexPath.row];
    
    //NSLog(@"%@", tweet);
    
    cell.titleLabel.text = [NSString stringWithFormat:@"%@ @%@", [[tweet objectForKey:@"user"] valueForKey:@"name"], [[tweet objectForKey:@"user"] valueForKey:@"screen_name"]];
    
    cell.subtitleLabel.text = [tweet valueForKey:@"text"];
    
    cell.subtitleLabel.detectionBlock = ^(STTweetHotWord hotWord, NSString *string, NSString *protocol, NSRange range) {
        
        NSArray *hotWords = @[@"Handle", @"Hashtag", @"Link"];
        NSLog(@"%@", [NSString stringWithFormat:@"%@ [%d,%d]: %@%@", hotWords[hotWord], (int)range.location, (int)range.length, string, (protocol != nil) ? [NSString stringWithFormat:@" *%@*", protocol] : @""]);
    };
    
    NSString *dateString = [tweet valueForKey:@"created_at"];
    
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"]];
    [df setFormatterBehavior:NSDateFormatterBehavior10_4];
    [df setDateFormat:@"EEE MMM dd HH:mm:ss Z yyyy"];
    NSDate *convertedDate = [df dateFromString:dateString];
    NSDate *todayDate = [NSDate date];
    double ti = [convertedDate timeIntervalSinceDate:todayDate];
    ti = ti * -1;
    if(ti < 1) {
        dateString = @"jamais";
        NSLog(@"%@", dateString);
    } else 	if (ti < 60) {
        int diff = round(ti < 60);
        dateString = [NSString stringWithFormat:@"%dsec", diff];
        NSLog(@"%@", dateString);
    } else if (ti < 3600) {
        int diff = round(ti / 60);
        dateString = [NSString stringWithFormat:@"%dm", diff];
        NSLog(@"%@", dateString);
    } else if (ti < 86400) {
        int diff = round(ti / 60 / 60);
        dateString = [NSString stringWithFormat:@"%dh", diff];
        NSLog(@"%@", dateString);
    } else if (ti < 2629743) {
        int diff = round(ti / 60 / 60 / 24);
        dateString = [NSString stringWithFormat:@"%dj", diff];
        NSLog(@"%@", dateString);
    } else {
        dateString =  @"never";
        NSLog(@"%@", dateString);
    }
    
    cell.date.text = dateString;
    
    NSString *imageHD = [[tweet objectForKey:@"user"] valueForKey:@"profile_image_url"];
    
    NSString *stringWithoutSpaces = [imageHD
                                     stringByReplacingOccurrencesOfString:@"_normal" withString:@""];
    
    NSLog(@"%@", imageHD);
    
    cell.profileImage.layer.cornerRadius = 25.5;
    cell.profileImage.layer.masksToBounds = YES;
    
    /*
    cell.profileImage.layer.borderWidth = 1;
    cell.profileImage.layer.borderColor = [UIColor colorWithHexString:@"#283746"].CGColor;
    cell.profileImage.clipsToBounds = YES;
     */
    
    /*
     int randomNumber = arc4random() %4;
         
         switch (randomNumber) {
             case kCouleurRouge:
                 NSLog(@"On set la couleur rouge");
                 cell.profileImage.layer.borderColor = [UIColor blueColor].CGColor;
                 break;
             case kCouleurBleu:
                 NSLog(@"On set la couleur bleu");
                 cell.profileImage.layer.borderColor = [UIColor greenColor].CGColor;
                 break;
             case kCouleurVert:
                 NSLog(@"On set la couleur vert");
                 cell.profileImage.layer.borderColor = [UIColor blackColor].CGColor;
                 break;
             case kCouleurJaune:
                 NSLog(@"On set la couleur jaune");
                 cell.profileImage.layer.borderColor = [UIColor lightGrayColor].CGColor;
                 break;
             default:
                 NSLog(@"Erreur");
                 break;
         }
     */
    
    SDWebImageManager *manager = [SDWebImageManager sharedManager];
    [manager downloadImageWithURL:[NSURL URLWithString:stringWithoutSpaces]
                          options:0
                         progress:^(NSInteger receivedSize, NSInteger expectedSize) {
                             // progression tracking code
                         }
                        completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
                            if (image) {
                                // do something with image
                                cell.profileImage.image = image;
                                [cell.profileImage setClipsToBounds:YES];
                            }
                        }];
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([self hasImageAtIndexPath:indexPath]) {
        return [self heightForImageCellAtIndexPath:indexPath];
    } else {
        return [self heightForBasicCellAtIndexPath:indexPath];
    }
}

- (CGFloat)heightForImageCellAtIndexPath:(NSIndexPath *)indexPath {
    static RWImageCell *sizingCell = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sizingCell = [self.tableView dequeueReusableCellWithIdentifier:RWImageCellIdentifier];
    });
    
    [self configureImageCell:sizingCell atIndexPath:indexPath];
    return [self calculateHeightForConfiguredSizingCell:sizingCell];
}

- (CGFloat)heightForBasicCellAtIndexPath:(NSIndexPath *)indexPath {
    static RWBasicCell *sizingCell = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sizingCell = [self.tableView dequeueReusableCellWithIdentifier:RWBasicCellIdentifier];
    });
    
    [self configureBasicCell:sizingCell atIndexPath:indexPath];
    return [self calculateHeightForConfiguredSizingCell:sizingCell];
}

- (CGFloat)calculateHeightForConfiguredSizingCell:(UITableViewCell *)sizingCell {
    
    sizingCell.bounds = CGRectMake(0.0f, 0.0f, CGRectGetWidth(self.tableView.frame), CGRectGetHeight(sizingCell.bounds));
    
    [sizingCell setNeedsLayout];
    [sizingCell layoutIfNeeded];
    
    CGSize size = [sizingCell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
    return size.height + 1.0f; // Add 1.0f for the cell separator height
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([self isLandscapeOrientation]) {
        if ([self hasImageAtIndexPath:indexPath]) {
            return 140.0f;
        } else {
            return 120.0f;
        }
    } else {
        if ([self hasImageAtIndexPath:indexPath]) {
            return 235.0f;
        } else {
            return 155.0f;
        }
    }
}

- (BOOL)isLandscapeOrientation {
    return UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation);
}

-(void) refreshInvoked:(id)sender forState:(UIControlState)state {
    // Refresh table here...
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    [self twitterTimeline];
    [self.tableView reloadData];
    [NSTimer scheduledTimerWithTimeInterval:2.5 target:self selector:@selector(endRefresh) userInfo:nil repeats:NO];
}

- (void)endRefresh
{
    [self.refreshControl endRefreshing];
    // show in the status bar that network activity is stoping
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

#pragma mark - Navigation

@end
