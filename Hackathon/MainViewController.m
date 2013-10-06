//
//  MainViewController.m
//  Hackathon
//
//  Created by David Quesada on 9/28/12.
//  Copyright (c) 2012 David Quesada. All rights reserved.
//

#import "MainViewController.h"
#import "CardView.h"
#import "PlayPreviewView.h"
#import "Game.h"
#import <QuartzCore/QuartzCore.h>

@interface MainViewController ()
{
    Game *game;
    UIView *cardCover;
    
    NSMutableArray *opponentDeck; // Array of CardView objects.
    int numberOfOpponentCards;

    UIAlertView *winAlertView;
    UIAlertView *loseAlertView;
    
    BOOL _isDoingHint;
}
@end

@implementation MainViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    tipsView.center = CGPointMake(160+320, 114);
    //tipsView.layer.borderColor = [UIColor blackColor].CGColor;
    //tipsView.layer.borderWidth = 3.5;
    tipsView.layer.cornerRadius = 7;
    tipsView.layer.masksToBounds = YES;
    
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"greenBackground"]];
    
    game = [Game game];
    game.mainVC = self;
    opponentDeck = [[NSMutableArray alloc] initWithCapacity:13];
    numberOfOpponentCards = 13;
    
    cardCover = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 1000, self.myDeckScrollView.frame.size.height)];
    cardCover.backgroundColor = [UIColor colorWithWhite:0 alpha:.35];
    self.myDeckScrollView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"DeckBackground"]];
    
    self.opponentDeckView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"OpponentDeckBackground"]];
    
    self.opponentDeckView.layer.shadowOpacity = 1.0;
    self.opponentDeckView.layer.shadowColor = [UIColor blackColor].CGColor;
    self.opponentDeckView.layer.shadowRadius = 10;
    
    self.opponentDeckView.layer.borderColor = [UIColor blackColor].CGColor;
    self.opponentDeckView.layer.borderWidth = 1;
    self.opponentDeckView.frame = CGRectMake(-1, self.opponentDeckView.frame.origin.y, 322, self.opponentDeckView.frame.size.height + 1);
    
    self.myDeckScrollView.layer.borderColor = [UIColor blackColor].CGColor;
    self.myDeckScrollView.layer.borderWidth = 1;
    self.myDeckScrollView.frame = CGRectOffset(CGRectInset(self.myDeckScrollView.frame, -1, -1), 0, 1);
    
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(0, self.opponentDeckView.layer.bounds.size.height)];
    [path addLineToPoint:CGPointMake(self.opponentDeckView.layer.bounds.size.width, self.opponentDeckView.layer.bounds.size.height)];
    
    self.opponentDeckView.layer.shadowPath = [UIBezierPath bezierPathWithRect:self.opponentDeckView.layer.bounds].CGPath;
    self.opponentDeckView.layer.masksToBounds = NO;
	// Do any additional setup after loading the view.
    
    [self loadOpponentDeck];
    
    NSArray *cardViews = [self generateViewsInMyDeckForCardIndexes:[Game game].deck];
    [self positionViewsInMyDeck:cardViews];
    
    [self setCanPlay:game.isMyTurn];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [game sendDataToOpponent:@{@"key" : @"exitGame"}];
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    [winAlertView dismissWithClickedButtonIndex:2 animated:animated];
    [loseAlertView dismissWithClickedButtonIndex:2 animated:animated];
}

-(void)setCanPlay:(BOOL)canPlay
{
    _isDoingHint = YES;
    if (canPlay)
    {
        //[cardCover removeFromSuperview];
        //self.myDeckScrollView.scrollEnabled = YES;
        for (CardView *v in self.myDeckScrollView.subviews)
        {
            if ([v isKindOfClass:[CardView class]])
                v.selectable = YES;
        }
        if (game.currentRestriction == RestrictionLowestCard)
        {
            waitingActivityIndicator.hidden = YES;
            waitingLabel.hidden = NO;
            waitingLabel.text = @"You play first.";
            self.playToolbarButton.enabled = NO;
            waitingView.hidden = NO;
        } else
            waitingView.hidden = YES;
    }
    else
    {
        //[self.myDeckScrollView addSubview:cardCover];
        //self.myDeckScrollView.scrollEnabled = NO;
        for (CardView *v in self.myDeckScrollView.subviews)
        {
            if ([v isKindOfClass:[CardView class]])
                v.selectable = NO;
        }
        
        self.playToolbarButton.enabled = NO;
        self.passToolbarButton.enabled = NO;
        
        waitingLabel.text = @"Waiting for Opponent";
        waitingView.hidden = NO;
        waitingActivityIndicator.hidden = NO;
        [waitingActivityIndicator startAnimating];
    }
    _isDoingHint = NO;
}

// v = true => show play button.
// v = false => show pass button.
-(void)setPlayButtonAndNotPassButtonIsVisible:(BOOL)v
{
    NSMutableArray *items = [deckToolbar.items mutableCopy];
    [items removeLastObject];
    if (v)
        [items addObject:self.playToolbarButton];
    else
        [items addObject:self.passToolbarButton];
    self.passToolbarButton.enabled = game.isMyTurn && (game.currentRestriction != RestrictionFreedom);
    
    //[deckToolbar setItems:items animated:YES];
    deckToolbar.items = items;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



- (IBAction)applyHint:(id)sender {
    NSArray *indexesToSelect = tipsHintCards;
    _isDoingHint = YES;
    for (CardView *card in self.myDeckScrollView.subviews)
    {
        if ([card isKindOfClass:[CardView class]])
        {
            card.isSelected = NO;//[indexesToSelect containsObject:@(card.cardIndex)];
        }
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        for (CardView *card in self.myDeckScrollView.subviews)
        {
            if ([card isKindOfClass:[CardView class]])
            {
                card.isSelected = [indexesToSelect containsObject:@(card.cardIndex)];
            }
        }
        
        int positionOfFirstCard;
        if (indexesToSelect.count)
            positionOfFirstCard = [game.deck indexOfObject:[indexesToSelect objectAtIndex:0]];
        else
            positionOfFirstCard = 0;
        [self.myDeckScrollView scrollRectToVisible:[self frameForCardInMyHandAtIndex:positionOfFirstCard] animated:YES];
        
        _isDoingHint = NO;
        [self playSelectionSound:YES];
    });
}

- (NSArray *)generateViewsInMyDeckForCardIndexes:(NSArray *)indexes
{
    NSMutableArray *array = [[NSMutableArray alloc] initWithCapacity:indexes.count];
    
    for (int i = 0; i < indexes.count; i++)
    {
        int index = [[indexes objectAtIndex:i]integerValue];
        CardView *view = [[CardView alloc] initWithFrame:[self frameForCardInMyHandAtIndex:i] cardIndex:index];
        view.mainView = self;
        [array addObject:view];
    }
    return array;
}

// Sizing constants

#define MY_HAND_TOP_SPACING 25
#define MY_HAND_BOTTOM_SPACING 10
#define MY_HAND_SIDE_PADDING 10
#define MY_HAND_SPACING -25

-(CGFloat)widthForMyHandWithNumberOfCards:(int)count cardWidth:(CGFloat)iwidth
{
    if (count == 0)
        return 2 * MY_HAND_SIDE_PADDING;
    if (count == 1)
        return 2 * MY_HAND_SIDE_PADDING + iwidth;
    return 2 * MY_HAND_SIDE_PADDING + iwidth * count + MY_HAND_SPACING * (count - 1);
}

-(CGFloat)cardWidth
{
    return (self.myDeckScrollView.frame.size.height - MY_HAND_TOP_SPACING - MY_HAND_BOTTOM_SPACING) * (72.0/96.0);
}

-(CGRect)frameForCardInMyHandAtIndex:(int)index
{
    CGSize itemsize = CGSizeMake(0, self.myDeckScrollView.frame.size.height - MY_HAND_TOP_SPACING - MY_HAND_BOTTOM_SPACING);
    itemsize.width = itemsize.height * (72.0/96.0);
    
    return CGRectMake(MY_HAND_SIDE_PADDING + index * (itemsize.width + MY_HAND_SPACING), MY_HAND_TOP_SPACING, itemsize.width, itemsize.height);
}

-(void)removeCardsFromMyHandAtPositions:(NSArray *)positions
{
    NSMutableArray *cardsToRemove = [[NSMutableArray alloc] initWithCapacity:positions.count];
    
    [UIView animateWithDuration:.3 animations:^{
        NSMutableArray *cardsLeft = [self.myDeckScrollView.subviews mutableCopy];
        [self.myDeckScrollView.subviews enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            if ([positions containsObject:@(idx)])
            {
                CardView *card = obj;
                card.frame = CGRectMake(card.center.x, card.center.y, 0, 0);
                card.alpha = 0.0;
                [cardsLeft removeObject:obj];
                [cardsToRemove addObject:obj];
            }
        }];
        [cardsLeft enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            CardView *card = obj;
            card.frame = [self frameForCardInMyHandAtIndex:idx];
        }];
        self.myDeckScrollView.contentSize = CGSizeMake([self widthForMyHandWithNumberOfCards:cardsLeft.count cardWidth:[self cardWidth]], self.myDeckScrollView.frame.size.height);
    } completion:^(BOOL finished) {
        for (UIView *view in cardsToRemove)
            [view removeFromSuperview];
    }];
}

#define OPPONENT_TOP_PADDING 8.0
#define OPPONENT_BOTTOM_PADDING 8.0
#define OPPONENT_SIDE_PADDING 10.0
#define OPPONENT_HSPACING -10.0

- (void)loadOpponentDeck
{
    //[self playSound:@"shuffle"];
    for (UIView *view in self.opponentDeckContainer.subviews.copy)
        [view removeFromSuperview];
    if (!opponentDeck.count)
    {
        for (int i = 0; i < 13; i++)
        {
            CardView *card = [[CardView alloc] initBackWithFrame:CGRectZero];
            card.selectable = NO;
            [opponentDeck addObject:card];
        }
    }
    
    
    CGSize cardSize = [self calculateSizeForOpponentDeckOfSize:13];
    CGFloat containerWidth = [self calculateWidthForOpponentDeckOfSize:13 withCardSize:cardSize];
    
    CGFloat initialDelay = 0.3;
    CGFloat delayPerCard = .39;
    CGFloat animationSpeed = .2;
    
    
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, initialDelay * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [self playSound:@"deal"];
    });
    
    for (int i = 0; i < 13; i++)
    {
        CardView *card = [opponentDeck objectAtIndex:i];
        card.alpha = 1.0;
        card.frame = CGRectMake(320, 0, cardSize.width, cardSize.height);
        
        [UIView animateWithDuration:animationSpeed delay:(initialDelay + i * delayPerCard) options:UIViewAnimationOptionCurveEaseOut animations:^{
            card.frame = CGRectMake(i * (cardSize.width + OPPONENT_HSPACING), 0, cardSize.width, cardSize.height);
        } completion:^(BOOL finished) {
            
        }];
        
        [self.opponentDeckContainer addSubview:card];
    }
    
    self.opponentDeckContainer.backgroundColor = [UIColor clearColor];
    self.opponentDeckContainer.frame = CGRectMake(0, 0, containerWidth, cardSize.height);
                                                  //self.opponentDeckContainer.superview.frame.size.height);
    self.opponentDeckContainer.center = [self.opponentDeckView convertPoint:self.opponentDeckView.center toView:self.opponentDeckView];
    
    numberOfOpponentCards = 13;
}

-(CGFloat)cardRatio
{
    return 96.0/72.0;
}

-(CGFloat)calculateWidthForOpponentDeckOfSize:(int)size withCardSize:(CGSize)cardSize
{
    if (!size)
        return 0;
    if (size == 1)
        return cardSize.width;
    return size * cardSize.width + (size - 1) * OPPONENT_HSPACING;\
}

// Calculates the size of one card.
- (CGSize)calculateSizeForOpponentDeckOfSize:(int)size
{
    CGSize availableSpace = self.opponentDeckView.bounds.size;
    availableSpace.height -= OPPONENT_TOP_PADDING;
    availableSpace.height -= OPPONENT_BOTTOM_PADDING;
    availableSpace.width -= 2 * OPPONENT_SIDE_PADDING;
    
    if (!size)
        return CGSizeZero;
    if (size == 1)
        return CGSizeMake(availableSpace.height / [self cardRatio], availableSpace.height);
    
    CGFloat idealWidth = (availableSpace.width - (size - 1) * OPPONENT_HSPACING) / (CGFloat)size;
    CGFloat correspondingHeight = idealWidth * [self cardRatio];
    
    if (correspondingHeight <= availableSpace.height)
        return CGSizeMake(idealWidth, correspondingHeight);
    
    idealWidth *= (availableSpace.height / correspondingHeight);
    correspondingHeight = availableSpace.height;
        return CGSizeMake(idealWidth, correspondingHeight);
}

//-(CGRect)frameForOpponentCardAtIndex:(NSInd)

- (void)positionViewsInMyDeck:(NSArray *)views
{
    for (UIView *v in self.myDeckScrollView.subviews.copy)
    {
        [v removeFromSuperview];
    }
    for (UIView *v in views)
    {
        [self.myDeckScrollView addSubview:v];
    }
    
    self.myDeckScrollView.contentSize = CGSizeMake([self widthForMyHandWithNumberOfCards:views.count cardWidth:[self cardWidth]], self.myDeckScrollView.frame.size.height);
}

- (IBAction)playMove:(id)sender
{
    [self dismissTip:nil];
    [self.myPreviewView setGlowVisible:NO animated:YES];
    self.myPreviewView.isUpdating = YES;
    NSArray *cardValues = [self selectedCardValues];

    game.isMyTurn = NO;
    game.cardToBeat = [cardValues.lastObject integerValue];
    [game sendDataToOpponent:@{@"key" : @"opponentDidMove" , @"cards" : cardValues, @"cardToBeat" : @(game.cardToBeat) }];
    
    [self removeCardsFromMyHandAtPositions:[self selectedCardPositions]];
    
    [[game deck] removeObjectsInArray:cardValues];
    
    [self setCanPlay:NO];
    
    waitingLabel.text = @"Waiting for Opponent";
    for (UIBarButtonItem *item in deckToolbar.items)
        item.enabled = NO;
    waitingActivityIndicator.hidden = NO;
    [waitingActivityIndicator startAnimating];
    waitingView.hidden = NO;
    
    [self playSound:@"placeCards"];
}

-(void)alertViewCancel:(UIAlertView *)alertView
{
    NSLog(@"Alertview canceled");
}

-(void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0) // No
    {
        [game sendDataToOpponent:@{@"key" : @"exitGame"}];
        [game handleData:@{@"key" : @"exitGame"}];
    } else if (buttonIndex == 1) // Yes
    {
        //[self doGameOverAnimations];
        
        // Start a new game here.
        // shuffle The deck here.
        
        id deck = [game generateOrderedDeck];
        
        id myHand = [game extract13CardsFromDeck:deck];
        myHand = [myHand sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            return [obj1 compare:obj2];
        }];
        
        id opponentHand = [game extract13CardsFromDeck:deck];
        opponentHand = [opponentHand sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            return [obj1 compare:obj2];
        }];
        
        BOOL iHaveALowerCardThanTheOpponent = [[myHand objectAtIndex:0] integerValue] < [[opponentHand objectAtIndex:0] integerValue];
        
        id myData = @{@"key" : @"playAgain", @"hand" : myHand, @"startsFirst" : @(iHaveALowerCardThanTheOpponent) };
        id opponentData = @{@"key" : @"playAgain", @"hand" : opponentHand, @"startsFirst" : @(!iHaveALowerCardThanTheOpponent) };
        
        [game sendDataToOpponent:opponentData];
        [game handleData:myData];
    }
}

- (IBAction)passMove:(id)sender {
    [self.myPreviewView clearCardsToRight];
    
    [self dismissTip:nil];
    
    game.isMyTurn = NO;
    [self setCanPlay:NO];
    [game sendDataToOpponent:@{@"key":@"opponentDidMove", @"cards":@[]}];
    
    [deckToolbar.items.lastObject setEnabled:NO];
    _isDoingHint = YES;
    [UIView animateWithDuration:.12 animations:^{
        for (CardView *view in self.myDeckScrollView.subviews)
        {
            if ([view isKindOfClass:[CardView class]])
            {
                view.isSelected = NO;
            }
        }
    }];
    _isDoingHint = NO;
    [self playSound:@"placeCards"];
}


-(NSArray *)selectedCards
{
    NSMutableArray *array = [[NSMutableArray alloc] init];
    for (CardView *card in self.myDeckScrollView.subviews)
    {
        if ([card isKindOfClass:[CardView class]] && card.isSelected)
            [array addObject:card];
    }
    return array;
}

-(NSArray *)selectedCardPositions
{
    NSMutableArray *array = [[NSMutableArray alloc] init];
    for (int i = 0; i < self.myDeckScrollView.subviews.count; i++)
    {
        id subview = [self.myDeckScrollView.subviews objectAtIndex:i];
        if ([subview isKindOfClass:[CardView class]] && [subview isSelected])
            [array addObject:@(i)];
    }
    return array;
}

-(NSArray *)selectedCardValues
{
    NSMutableArray *array = [[NSMutableArray alloc] init];
    for (CardView *card in self.myDeckScrollView.subviews)
    {
        if ([card isKindOfClass:[CardView class]] && card.isSelected)
            [array addObject:@(card.cardIndex)];
    }
    return array;
}

// To be called from CardView

-(void)cardWasSelected:(CardView *)card
{
    [self.myPreviewView addCard:card.cardIndex fromScreenFrame:[card convertRect:card.bounds toView:nil]];
    [self cardSelectionWasChanged];
}
-(void)cardWasDeselected:(CardView *)card
{
    [self.myPreviewView removeCard:card.cardIndex toScreenFrame:[card convertRect:card.bounds toView:nil]];
    [self cardSelectionWasChanged];
}

-(void)playSelectionSound:(BOOL)isSelected
{
    if (!_isDoingHint)
        [self playSound:@"select"];
}

-(void)cardSelectionWasChanged
{
    // TODO: Consider the legality of the move here.
    
    //BOOL legal = (self.selectedCardPositions.count % 2) == 1;// We have an odd number of cards.
    
    BOOL legal = YES;
    
    NSArray *selectedCards = [self selectedCardValues];
    
    legal = [game handSatisfiesRestriction:selectedCards];
    
//    [game performsele]
    
    legal = legal && game.isMyTurn;
    
    [self setPlayButtonAndNotPassButtonIsVisible:(selectedCards.count || game.currentRestriction == RestrictionLowestCard || game.currentRestriction == RestrictionFreedom)];
    
    [self setPlayIsLegal:legal];
}

-(void)setPlayIsLegal:(BOOL)legal
{
    self.myPreviewView.playIsLegal = legal;
    self.playToolbarButton.enabled = legal;
}

-(void)playOpponentCards:(NSArray *)cards
{
    [self dismissTip:nil];
    BOOL shouldshowplaybutton = NO;
    if (cards.count == numberOfOpponentCards)
    {
        //TODO: They won here.
        
        [game sendDataToOpponent:@{@"key" : @"win"}];
        [game handleData:@{@"key" : @"lose" }];
        
        game.opponentScore++;
        
        [game sendDataToOpponent:@{@"key" : @"updateScore" , @"myScore" : @(game.opponentScore), @"opponentScore":@(game.myScore)}];
        [self updateScore];
        
        [UIView animateWithDuration:.5 animations:^{
            for (UIView *v in self.opponentDeckContainer.subviews)
                v.alpha = 0.0;
        }];
        waitingView.hidden = YES;
        return;
    }
    if (cards.count > numberOfOpponentCards)
    {
        // TODO:
        // All hell has broken loose. What do we do?
        return;
    }
    if (cards.count == 0)
    {
        game.currentRestriction = RestrictionFreedom;
        
        waitingLabel.text = @"Opponent Passed";
        waitingView.hidden = NO;
        waitingActivityIndicator.hidden = YES;
        
        shouldshowplaybutton = YES;
    }
    else // Removed a non-zero amount of cards but didn't win yet.
        waitingView.hidden = YES;
    
    [self playSound:@"placeCards"];
    
    CGFloat width = [self calculateSizeForOpponentDeckOfSize:13].width;
    
    [UIView animateWithDuration:.5 animations:^{
        NSArray *cardsToRemove = [opponentDeck subarrayWithRange:NSMakeRange(numberOfOpponentCards - cards.count, cards.count)];
        for (CardView *card in cardsToRemove)
            card.alpha = 0.0;
        
        self.opponentDeckContainer.frame = CGRectInset(self.opponentDeckContainer.frame, .5 * cards.count * (width + OPPONENT_HSPACING), 0);
    }];
    
    numberOfOpponentCards -= cards.count;
    
//    for (int i = 0; i < )

    [self.opponentPreviewView clearCardsToLeft];
    
    //int64_t delayInSeconds = 2.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, .4 * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [self.opponentPreviewView setGlowVisible:NO animated:NO];
        for (int i = 0; i < cards.count; i++)
        {
            [self.opponentPreviewView addCard:[[cards objectAtIndex:i]integerValue] ];
        }
    });
    
    [self.myPreviewView clearCardsToRight];
    [self.myPreviewView setGlowVisible:YES animated:NO];
    
    [self setPlayButtonAndNotPassButtonIsVisible:shouldshowplaybutton];
}

-(void)setupForPlayAgain
{
    [winAlertView dismissWithClickedButtonIndex:2 animated:YES];
    [loseAlertView dismissWithClickedButtonIndex:2 animated:YES];
    
    numberOfOpponentCards = 13;
    
    [self loadOpponentDeck];
    
    NSArray *cardViews = [self generateViewsInMyDeckForCardIndexes:[Game game].deck];
    [self positionViewsInMyDeck:cardViews];
    
    [self setCanPlay:game.isMyTurn];
}

-(void)doGameOverAnimations
{
    [self.myPreviewView clearCardsToRight];
    [self.opponentPreviewView clearCardsToLeft];
    
    [UIView animateWithDuration:.2 animations:^{
        for (UIView *v in self.myDeckScrollView.subviews)
        {
            v.frame = CGRectOffset(v.frame, 0, v.superview.frame.size.height);
            v.alpha = 0.0;
        }
    } completion:^(BOOL finished) {
        for (UIView *v in self.myDeckScrollView.subviews.copy)
            [v removeFromSuperview];
    }];
}

-(void)didLose
{
    if (loseAlertView == nil)
        loseAlertView = [[UIAlertView alloc] initWithTitle:@"Lose" message:@"You lost. Do you want to play again?" delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
    [self playSound:@"loseSound"];
    [loseAlertView show];
    [self doGameOverAnimations];
}

-(void) playSound:(NSString *)soundName
{
    CFBundleRef mainBundle = CFBundleGetMainBundle();
    CFURLRef soundFileURL;
    soundFileURL = CFBundleCopyResourceURL(mainBundle, (__bridge CFStringRef) soundName, CFSTR ("m4a") , NULL);
    UInt32 soundID;
    AudioServicesCreateSystemSoundID(soundFileURL,&soundID);
    AudioServicesPlaySystemSound(soundID);
}

-(void)didWin
{
    if (winAlertView == nil)
        winAlertView = [[UIAlertView alloc] initWithTitle:@"Win" message:@"You won. Do you want to play again?" delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
    [self playSound:@"winSound"];
    [winAlertView show];
    [self doGameOverAnimations];
}

- (IBAction)dismissTip:(id)sender 
{
    if (!tipsIsShowing)
        return;
    tipsIsShowing = NO;
    [UIView animateWithDuration:.35 animations:^{
        tipsView.center = CGPointMake(160-320, 114);
        tipsView.alpha = 0.0;
    } completion:^(BOOL finished) {
        tipsView.center = CGPointMake(160+320, 114);
        tipsView.hidden = YES;
    }];
}

-(void)showHintText:(NSString *)text withHintCards:(NSArray *)cards
{
    tipsTextView.text = text;
    tipsHintButton.enabled = (cards.count > 0);
    tipsHintCards = cards;
    
    if (tipsIsShowing)
        return;
    tipsIsShowing = YES;
    tipsView.hidden = NO;
    [UIView animateWithDuration:.35 animations:^{
        tipsView.center = CGPointMake(160, 114);
        tipsView.alpha = 1.0;
    }];
}

// Return nil = No suggested hint (shouldn't do this eventually)
// Return 0-count array = No moves found
- (NSArray *)calculateHint
{
    int numtobeat = game.cardToBeat;
    
    if (![game deck].count)
        return [[NSArray alloc] init];
    
    if (  (game.currentRestriction == RestrictionSingle) ||
        (game.currentRestriction == RestrictionDouble) ||
        (game.currentRestriction == RestrictionTriple) ||
        (game.currentRestriction == RestrictionQuad))
    {
        int numtoPick = 1 + (game.currentRestriction - RestrictionSingle);
        
        if (numtoPick > game.deck.count)
            return [[NSArray alloc] init];
        
        for (int i = 0; i <= game.deck.count - numtoPick; i++)
        {
            // Do the next `numToPick` elements match? (Are they the same numeric value)
            BOOL doMatch = YES;
            int numval = [[game.deck objectAtIndex:i] integerValue] / 4;
            for (int n = i; n < i + numtoPick; n++)
            {
                if ([[game.deck objectAtIndex:n] integerValue] / 4 != numval)
                    doMatch = NO;
            }
            
            if (doMatch && ([[game.deck objectAtIndex:(i + numtoPick - 1)] integerValue] > numtobeat))
                return [game.deck subarrayWithRange:NSMakeRange(i, numtoPick)];
        }
        
        return [[NSArray alloc] init];
    } else if ( (game.currentRestriction == RestrictionFreedom) ||
                (game.currentRestriction == RestrictionLowestCard) )
    {
        
        // Find a straight starting with the lowest card.
        NSMutableArray *straight = [[NSMutableArray alloc] init];
        int element = [[game.deck objectAtIndex:0] integerValue] / 4;
        
        [straight addObject:[game.deck objectAtIndex:0]];
        
        for (int i = 1; i < game.deck.count; i++)
        {
            int thisCard = [[game.deck objectAtIndex:i] integerValue] / 4;
            if (thisCard == element + 1)
            {
                element ++;
                [straight addObject:[game.deck objectAtIndex:i]];
            }
        }
        
        if (straight.count >= 3)
            return straight;
        
        NSMutableArray *multi = [[NSMutableArray alloc] init];
        
        [multi addObject:[game.deck objectAtIndex:0]];
        
        element = [[game.deck objectAtIndex:0] integerValue] / 4;
        int currentIndex = 1;
        while (currentIndex < game.deck.count && [[game.deck objectAtIndex:currentIndex] integerValue] / 4 == element)
        {
            [multi addObject:[game.deck objectAtIndex:currentIndex++]];
        }
        
        return multi;
    } else if ( (game.currentRestriction >= Restriction3) &&
                (game.currentRestriction <= Restriction12) )
    {
        int requiredLength = 3 + (game.currentRestriction - Restriction3);
        
        if (requiredLength > game.deck.count)
            return [[NSArray alloc] init];
        
        int requiredEndingCard = game.cardToBeat + 1;
        int minimumStartCard = (requiredEndingCard / 4) - (requiredLength - 1);
        minimumStartCard *= 4;
        
        int startingIndex = 0;
        int startingCard = 0;
        BOOL canstart = NO;
        
        NSMutableArray *straight = [[NSMutableArray alloc] init];
        NSMutableArray *finalStraight = nil;
        
        // Go through all the cards and see if we can find a straight of the
        // first (n - 1) cards.
        
        for (; startingIndex < game.deck.count - (requiredLength + 1); startingIndex ++)
        {
            [straight removeAllObjects];
            int thisCard = [[game.deck objectAtIndex:startingIndex] integerValue];
            if (thisCard < minimumStartCard)
                continue;
            
            int element = thisCard / 4;
            [straight addObject:@(thisCard)];
            
            BOOL foundNMinusOne = NO;
            
            int position;
            // Do minus one, because if we go all the way to the end, that is our (n-1) array, and there would be no space for element n.
            for (position = startingIndex + 1; position < game.deck.count - 1; position++)
            {
                int elementOfThis = [[game.deck objectAtIndex:position] integerValue] / 4;
                
                if (elementOfThis == element + 1)
                {
                    element ++;
                    [straight addObject:[game.deck objectAtIndex:position]];
                }
                
                
                if (straight.count == requiredLength - 1)
                {
                    foundNMinusOne = YES;
                    break;
                }
            }
            
            // We found the first (n - 1) elements in our straight.
            if (foundNMinusOne)
            {
                // Now we need to try to find the last card 
                for (; position < game.deck.count; position++)
                {
                    int c = [[game.deck objectAtIndex:position] integerValue];
                    // If this card is the next in the series and is higher than the card to beat, we have our match.
                    if ((c/4 == element + 1) && (c > game.cardToBeat))
                    {
                        [straight addObject:@(c)];
                        return straight;
                    }
                }
            }
        }
        

//        return finalStraight;
        
        //Ignore this comment->  // At this point, straight should be a strait that stops one card short of its goal.
        return nil;;
    }
    
    
    return nil;
}

- (void)calculateAndShowTip
{
    if (![Game game].isMyTurn)
    {
        [self showHintText:@"Right now it is not your turn. When it comes to your turn, you will have the option to play cards that are higher than what was previously played or to pass." withHintCards:nil];
        return;
    }
    
    NSString *noOptions = @"\n\nYou have no available moves. Passing is suggested.";
    
    NSArray *patternTypes = @[
    @(RestrictionSingle),
    @(RestrictionDouble),
    @(RestrictionTriple),
    @(RestrictionQuad),
    @(Restriction3),
    @(Restriction4),
    @(Restriction5),
    @(Restriction6),
    @(Restriction7),
    @(Restriction8),
    @(Restriction9),
    @(Restriction10),
    @(Restriction11),
    @(Restriction12)
    ];
    
    // The current pattern is blah. You must either play blah2 or pass. [ You have at least one move available | You have no moves available and must pass ]
    if ([patternTypes containsObject:@(game.currentRestriction)])
    {
        NSArray *blah1 = @[
            @"single cards",
            @"two of a kind",
            @"three of a kind",
            @"four of a kind",
            @"3 card straight",
            @"4 card straight",
            @"5 card straight",
            @"6 card straight",
            @"7 card straight",
            @"8 card straight",
            @"9 card straight",
            @"10 card straight",
            @"11 card straight",
            @"12 card straight",
        ];
        NSArray *blah2 = @[
            @"any card that ranks higher the card just played",
            @"any two cards with the same number value",
            @"any three cards with the same number value",
            @"any four cards with the same number value",
            @"a straight of 3 consecutively numbered cards",
            @"a straight of 4 consecutively numbered cards",
            @"a straight of 5 consecutively numbered cards",
            @"a straight of 6 consecutively numbered cards",
            @"a straight of 7 consecutively numbered cards",
            @"a straight of 8 consecutively numbered cards",
            @"a straight of 9 consecutively numbered cards",
            @"a straight of 10 consecutively numbered cards",
            @"a straight of 11 consecutively numbered cards",
            @"a straight of 12 consecutively numbered cards",
        ];
        int index = [patternTypes indexOfObject:@(game.currentRestriction)];
        
        NSArray *hint = [self calculateHint];
        
        NSString *text = [NSString stringWithFormat:@"The current pattern is %@. You must either play %@ or pass.%@", [blah1 objectAtIndex:index], [blah2 objectAtIndex:index], (hint.count ? @"" : noOptions)];
        
        [self showHintText:text withHintCards:hint];
        return;
    }
    if (game.currentRestriction == RestrictionLowestCard)
    {
        
        NSString *text = @"You are leading the match because you have the lowest card in play. You must play a legal combination that includes your lowest card.";

        [self showHintText:text withHintCards:[self calculateHint]];
        return;
    }
    if (game.currentRestriction == RestrictionFreedom)
    {
        NSString *text = @"You may play a single card or any legal combination you can make.";
        
        [self showHintText:text withHintCards:[self calculateHint]];
        return;
    }
}

- (IBAction)showTip:(id)sender {
    if (tipsIsShowing)
        [self dismissTip:nil];
    else
        [self calculateAndShowTip];
}

- (void)updateScore
{
    myScoreLabel.text = [NSString stringWithFormat:@"%d", game.myScore];
    opponentScoreLabel.text = [NSString stringWithFormat:@"%d", game.opponentScore];
}

@end
