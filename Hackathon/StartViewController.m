//
//  StartViewController.m
//  Hackathon
//
//  Created by David Quesada on 9/28/12.
//  Copyright (c) 2012 David Quesada. All rights reserved.
//

#import "StartViewController.h"
#import "MainViewController.h"
#import "Game.h"
#import "AppDelegate.h"
#import <GameKit/GameKit.h>
#import <QuartzCore/QuartzCore.h>

@interface StartViewController ()
{
    GKSession *mySession;
    GKPeerPickerController *peerPicker;
    NSMutableArray *peers;
}
@end

@implementation StartViewController
@synthesize startDictionary;

-(void)startGameWithDictionary:(NSDictionary *)dict
{
    self.startDictionary = dict;
    [self performSegueWithIdentifier:@"startGame" sender:self];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"startGame"])
    {
        
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if ([AppDelegate isIOS7])
        self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    
    [self.navigationController setNavigationBarHidden:YES animated:NO];
    
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"greenBackground"]];
    
    peers = [[NSMutableArray alloc] init];
    
    peerPicker = [[GKPeerPickerController alloc] init];
    peerPicker.delegate = self;
    
    logoImageView.layer.shadowColor = [UIColor whiteColor].CGColor;//[UIColor blackColor].CGColor;
    logoImageView.layer.shadowOpacity = .6;
    logoImageView.layer.shadowRadius = 8;
    logoImageView.layer.shouldRasterize = YES;
    logoImageView.layer.rasterizationScale = [UIScreen mainScreen].scale;
    
    if (![AppDelegate isIOS7])
    for (UIView *v in self.thistoolbar.subviews.copy)
    {
        if (![[[v class] description] isEqualToString:@"UIToolbarTextButton"])
            [v removeFromSuperview];
    }
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)start:(id)sender
{
    peerPicker.connectionTypesMask = GKPeerPickerConnectionTypeNearby;
//    GKPeerpick
//    peerPicker.
    [peerPicker show];
    [Game reset];
    [Game game].startVC = self;
}

- (IBAction)showRules:(id)sender
{
    UIToolbar *rulesBar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, 280, 44)];
    [rulesBar setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin];
    
    rulesBar.tintColor = [UIColor colorWithRed:100.0/255.0 green:41.0/255.0 blue:15.0/255.0 alpha:1];
    
    UIBarButtonItem *done = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleBordered target:self action:@selector(hideRules)];
    //[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIbarbut target:self action:@selector(hideRules)];
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
    UIBarButtonItem *tinySpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    tinySpace.width = 1.0;
    
    rulesBar.items = @[flexibleSpace,done,tinySpace];
    
    
    [rules addSubview:rulesBar];
    
    rules.layer.masksToBounds = YES;
    rules.layer.cornerRadius = 7;
    rules.layer.borderColor = [UIColor blackColor].CGColor;
    rules.layer.borderWidth = 3.5;
    
    rules.hidden = NO;
    
    [UIView animateWithDuration:.3 animations:^{
        CGRect rect = CGRectInset(self.view.bounds, 12, 12);
        if ([AppDelegate isIOS7])
        {
            rect.size.height -= 20;
            rect.origin.y += 20;
        }
        rules.frame = rect;
//        rules.frame = CGRectMake(20, 5, 280, 370);
//        rules.center = self.view.center;
    }];
}

-(void)hideRules
{
    CGFloat y = self.view.window.frame.size.height; // Wow, much dot syntax!
    if (![AppDelegate isIOS7])
        y -= 20;
    [UIView animateWithDuration:.3 animations:^{
        rules.frame = CGRectMake(20, y, 280, 370);
    }];
}



-(GKSession *)peerPickerController:(GKPeerPickerController *)picker sessionForConnectionType:(GKPeerPickerConnectionType)type
{
    mySession = [[GKSession alloc] initWithSessionID:@"com.gameof13" displayName:nil sessionMode:GKSessionModePeer];
    mySession.delegate = self;
    return mySession;
}

-(void)peerPickerController:(GKPeerPickerController *)picker didConnectPeer:(NSString *)peerID toSession:(GKSession *)session
{
    
    picker.delegate = self;
    [picker dismiss];
}

- (void)session:(GKSession *)session peer:(NSString *)peerID didChangeState:(GKPeerConnectionState)state
{
    if (state == GKPeerStateConnected)
    {
        [peers addObject:peerID];
        NSLog(@"Connected to %@",peerID);
        [Game game].gamekitPeers = peers;
        [Game game].gamekitSession = session;
        [session setDataReceiveHandler:self withContext:nil];
        
        
        int bid = (int)arc4random()%1000;
        
        [Game game].myShuffleBid = bid;
        
        NSLog(@"My Number: %d", bid);
        NSDictionary *data = @{ @"key" : @"InitialShuffleBid" , @"bid" : @(bid) };
        
        [[Game game] sendDataToOpponent:data];
    }
}

- (void) receiveData:(NSData *)data fromPeer:(NSString *)peer inSession: (GKSession *)session context:(void *)context
{
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
    [[Game game]handleData:dict];
}
@end
