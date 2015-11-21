//
//  ViewController.m
//  tabbar color
//
//  Created by Victor Pierre on 06/10/2015.
//  Copyright © 2015 Bernard Pierre. All rights reserved.
//

#import "ViewController.h"
#import "TWBSocialHelper.h"

@interface ViewController ()

@property (nonatomic) TWBSocialHelper *localInstance;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    _localInstance = [TWBSocialHelper sharedHelper];
    [self requestAccessToTwitter];
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
    
    self.label.text = @"Access ok, please clique a button";
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
