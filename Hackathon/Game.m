//
//  Game.m
//  Hackathon
//
//  Created by David Quesada on 9/28/12.
//  Copyright (c) 2012 David Quesada. All rights reserved.
//

#import "Game.h"
#import "StartViewController.h"
#import "MainViewController.h"

Game *globalGame;

@implementation Game

@synthesize myShuffleBid;

@synthesize gamekitPeers, gamekitSession;
@synthesize startVC, mainVC;

// Synthesize game info.
@synthesize isFirst, isMyTurn;
@synthesize myScore, opponentScore;

+ (Game *)reset
{
    globalGame = [[Game alloc] init];
    return globalGame;
}

+ (Game *)game
{
    if (globalGame)
        return globalGame;
    
    globalGame = [[Game alloc] init];
    return globalGame;
}

- (id)init
{
    self = [super init];
    if (self) {
        
    }
    return self;
}


-(void)sendDataToOpponent:(NSDictionary *)data
{
    NSMutableDictionary *dict = [data mutableCopy];
    NSString *key = [dict valueForKey:@"key"];
    
    if ([key isEqual:@"opponentDidMove"])
    {
        //if (self.isFirst)
        if (self.currentRestriction == RestrictionFreedom || self.currentRestriction == RestrictionLowestCard)
        {
            id cards = [dict valueForKey:@"cards"];
            Restriction newRestriction = [self patternOfCards:cards];
            [dict setValue:@(newRestriction) forKey:@"currentRestriction"];
            self.currentRestriction = newRestriction;
        }
        self.isFirst = NO;
    }
    
    [self.gamekitSession sendDataToAllPeers:[NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:nil] withDataMode:GKSendDataReliable error:nil];
}

-(void)handleData:(NSDictionary *)data
{
    NSString *key = [data valueForKey:@"key"];
    
    if ([key isEqualToString:@"InitialShuffleBid"])
    {
        int bid = [[data valueForKey:@"bid"] integerValue];
        
        NSString *text = [NSString stringWithFormat:@"My String: %d\nRecieved String: %d", self.myShuffleBid, bid];
        if (self.myShuffleBid > bid)
        {
            text = [text stringByAppendingString:@"\n\nTherefore, I shuffle."];
            // shuffle The deck here.
            
            id deck = [self generateOrderedDeck];
            
            id myHand = [self extract13CardsFromDeck:deck];
            myHand = [myHand sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
                return [obj1 compare:obj2];
            }];
            
            id opponentHand = [self extract13CardsFromDeck:deck];
            opponentHand = [opponentHand sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
                return [obj1 compare:obj2];
            }];
            
            BOOL iHaveALowerCardThanTheOpponent = [[myHand objectAtIndex:0] integerValue] < [[opponentHand objectAtIndex:0] integerValue];
            
            id myData = @{@"key" : @"beginGame", @"hand" : myHand, @"willShuffleNext" : @(YES), @"startsFirst" : @(iHaveALowerCardThanTheOpponent) };
            id opponentData = @{@"key" : @"beginGame", @"hand" : opponentHand, @"willShuffleNext" : @(NO) , @"startsFirst" : @(!iHaveALowerCardThanTheOpponent) };
            
            [self sendDataToOpponent:opponentData];
            [self handleData:myData];
        }
  
        NSLog(@"%@",text);
//        [[[UIAlertView alloc] initWithTitle:nil message:text delegate:nil cancelButtonTitle:@"Close" otherButtonTitles:nil, nil] show];
    }
    else if ([key isEqualToString:@"beginGame"])
    {
        self.deck = [[data valueForKey:@"hand"] mutableCopy];
        self.isMyTurn = [[data valueForKey:@"startsFirst"] integerValue];
        self.isFirst = YES;
        if (self.isMyTurn)
            self.currentRestriction = RestrictionLowestCard;
        [startVC startGameWithDictionary:data];
    } else if ([key isEqualToString:@"opponentDidMove"])
    {
        id r = [data valueForKey:@"currentRestriction"];
        if (r != nil)
            self.currentRestriction = (int)[r integerValue];
        r = [data valueForKey:@"cardToBeat"];
        if (r != nil)
            self.cardToBeat = [r integerValue];
        self.isMyTurn = YES;
        [self.mainVC setCanPlay:YES];
        NSArray *cards = [data valueForKey:@"cards"];
        //self.mainVC.playToolbarButton.enabled = YES;
        [self.mainVC playOpponentCards:cards];
        self.mainVC.opponentCards = cards;
    } else if ([key isEqualToString:@"win"])
    {
        [self.mainVC didWin];
    } else if ([key isEqualToString:@"lose"])
    {
        [self.mainVC didLose];
    } else if ([key isEqualToString:@"exitGame"])
    {
        //maybe close the session here?
        [self.gamekitSession disconnectFromAllPeers];
        
        [self.mainVC.navigationController popViewControllerAnimated:YES];
    } else if ([key isEqualToString:@"playAgain"])
    {
        self.deck = [[data valueForKey:@"hand"] mutableCopy];
        self.isMyTurn = [[data valueForKey:@"startsFirst"] integerValue];
        self.isFirst = YES;
        if (self.isMyTurn)
            self.currentRestriction = RestrictionLowestCard;
        [self.mainVC setupForPlayAgain];
    } else if ([key isEqualToString:@"updateScore"])
    {
        self.myScore = [[data valueForKey:@"myScore"] integerValue];
        self.opponentScore = [[data valueForKey:@"opponentScore"] integerValue];
        [self.mainVC updateScore];
    }
}


- (NSMutableArray *)generateOrderedDeck
{
    NSMutableArray *array = [[NSMutableArray alloc] initWithCapacity:52];
    for (int i = 0; i < 52; [array addObject:@(i++)]);
    return array;
}

- (NSMutableArray *)extract13CardsFromDeck:(NSMutableArray *)deck
{
    NSMutableArray *array = [[NSMutableArray alloc] initWithCapacity:13];
    for (int i = 0; i < 13; i++)
    {
        int index = arc4random() % deck.count;
        id val = [deck objectAtIndex:index];
        [deck removeObjectAtIndex:index];
        [array addObject:val];
    }
    return array;
}

-(Restriction)patternOfCards:(NSArray *)cards
{
    if (cards.count == 0)
        return RestrictionNone;
    
    if (cards.count == 1)
        return RestrictionSingle;
    
    if (cards.count == 2
        && (([[cards objectAtIndex:0] integerValue] / 4) == ([[cards objectAtIndex:1] integerValue] / 4)))
        return RestrictionDouble;
    
    if (cards.count == 3
        && (([[cards objectAtIndex:0] integerValue] / 4) == ([[cards objectAtIndex:1] integerValue] / 4))
        && (([[cards objectAtIndex:1] integerValue] / 4) == ([[cards objectAtIndex:2] integerValue] / 4))
        )
        return RestrictionTriple;
    
    if (cards.count == 4
        && (([[cards objectAtIndex:0] integerValue] / 4) == ([[cards objectAtIndex:1] integerValue] / 4))
        && (([[cards objectAtIndex:1] integerValue] / 4) == ([[cards objectAtIndex:2] integerValue] / 4))
        && (([[cards objectAtIndex:2] integerValue] / 4) == ([[cards objectAtIndex:3] integerValue] / 4))
        )
        return RestrictionQuad;
    
    BOOL isSequential = YES;
    int first = [[cards objectAtIndex:0] integerValue] / 4;
    for (int i = 1; i < cards.count; i++)
    {
        int element = [[cards objectAtIndex:i] integerValue] / 4;
        if (element != first + i)
        {
            isSequential = NO;
            break;
        }
    }
    
    if (isSequential && cards.count >= 3)
    {
        return (Restriction)(10 + cards.count);
    }
    
    return RestrictionNone;
}

-(BOOL)handSatisfiesRestriction:(NSArray *)cards
{
    if (self.currentRestriction == RestrictionLowestCard)
        return [cards containsObject:[self.deck objectAtIndex:0]] && ([self patternOfCards:cards] != RestrictionNone);
    // The player is leading a new pattern. Must play something.
    if (self.currentRestriction == RestrictionFreedom)
        return (cards.count != 0) && ([self patternOfCards:cards] != RestrictionNone);
    
    if (self.currentRestriction == RestrictionNone)
        return YES; // or no?
    
    // Otherwise, the candidate play must be the same pattern as the current play,
    // and the highest card must also be higher.
    return ([self patternOfCards:cards] == self.currentRestriction)
    && ([cards.lastObject integerValue] > self.cardToBeat);
}

@end
