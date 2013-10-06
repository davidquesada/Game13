//
//  MainViewController.h
//  Hackathon
//
//  Created by David Quesada on 9/28/12.
//  Copyright (c) 2012 David Quesada. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioToolbox.h>

@class CardView;
@class PlayPreviewView;

@interface MainViewController : UIViewController<UIAlertViewDelegate>
{
    IBOutlet UIToolbar *deckToolbar;
    IBOutlet UILabel *waitingLabel;
    IBOutlet UIView *waitingView;
    __weak IBOutlet UIActivityIndicatorView *waitingActivityIndicator;
    
    
    __weak IBOutlet UIView *tipsView;
    __weak IBOutlet UITextView *tipsTextView;
    __weak IBOutlet UIBarButtonItem *tipsHintButton;
    NSArray *tipsHintCards;
    
    __weak IBOutlet UILabel *myScoreLabel;
    __weak IBOutlet UILabel *opponentScoreLabel;
    
    BOOL tipsIsShowing;
}
- (IBAction)dismissTip:(id)sender;
- (IBAction)applyHint:(id)sender;
-(void)showHintText:(NSString *)text withHintCards:(NSArray *)cards;

-(NSArray *)generateViewsInMyDeckForCardIndexes:(NSArray *)indexes;

-(void)positionViewsInMyDeck:(NSArray *)views;

-(CGRect)frameForCardInMyHandAtIndex:(int)index;

-(void)removeCardsFromMyHandAtPositions:(NSArray *)positions;

-(void)setCanPlay:(BOOL)canPlay;
-(void)setPlayButtonAndNotPassButtonIsVisible:(BOOL)v;

-(void)playSelectionSound:(BOOL)isSelected;

@property (weak, nonatomic) IBOutlet UIView *opponentDeckView;
@property (weak, nonatomic) IBOutlet UIView *opponentDeckContainer;

- (IBAction)showTip:(id)sender;
@property (weak, nonatomic) IBOutlet UIScrollView *myDeckScrollView;
@property (weak, nonatomic) IBOutlet PlayPreviewView *opponentPreviewView;
@property (weak, nonatomic) IBOutlet PlayPreviewView *myPreviewView;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *playToolbarButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *passToolbarButton;
- (IBAction)playMove:(id)sender;
- (IBAction)passMove:(id)sender;

@property (strong, nonatomic) NSArray *opponentCards;

@property (readonly) NSArray *selectedCards;
@property (readonly) NSArray *selectedCardPositions;
@property (readonly) NSArray *selectedCardValues;

// To be called from CardView

-(void)cardWasSelected:(CardView *)card;
-(void)cardWasDeselected:(CardView *)card;

// Public-ish methods

-(void)setupForPlayAgain;
-(void)playOpponentCards:(NSArray *)cards;
-(void)didWin;
-(void)didLose;
-(void)updateScore;

-(void) playSound:(NSString *)soundName;

@end
