//
//  StartViewController.h
//  Hackathon
//
//  Created by David Quesada on 9/28/12.
//  Copyright (c) 2012 David Quesada. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GameKit/GameKit.h>
#import <AudioToolbox/AudioToolbox.h>

@interface StartViewController : UIViewController<GKSessionDelegate, GKPeerPickerControllerDelegate>
{
    IBOutlet UIImageView *logoImageView;
    IBOutlet UIView *rules;
}

@property NSDictionary *startDictionary;

-(void)startGameWithDictionary:(NSDictionary *)dict;
- (IBAction)start:(id)sender;

- (IBAction)showRules:(id)sender;

@property (weak, nonatomic) IBOutlet UIToolbar *thistoolbar;


@end
