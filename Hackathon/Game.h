//
//  Game.h
//  Hackathon
//
//  Created by David Quesada on 9/28/12.
//  Copyright (c) 2012 David Quesada. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GameKit/GameKit.h>

@class StartViewController, MainViewController;

typedef enum
{
    RestrictionLowestCard = -2,
    RestrictionFreedom = -1,
    
    RestrictionNone = 0,
    
    RestrictionSingle = 1,
    RestrictionDouble = 2,
    RestrictionTriple = 3,
    RestrictionQuad = 4,
    Restriction3 = 13,
    Restriction4 = 14,
    Restriction5 = 15,
    Restriction6 = 16,
    Restriction7 = 17,
    Restriction8 = 18,
    Restriction9 = 19,
    Restriction10 = 20,
    Restriction11 = 21,
    Restriction12 = 22
} Restriction;

@interface Game : NSObject

@property int myShuffleBid;


@property BOOL isMyTurn;
@property BOOL isFirst; // Is this the first play in the hand? (required to play 3-spades)
@property NSMutableArray *deck;

@property Restriction currentRestriction;
@property int cardToBeat;

@property int myScore;
@property int opponentScore;


@property NSArray *gamekitPeers;
@property GKSession *gamekitSession;

@property StartViewController *startVC;
@property MainViewController *mainVC;

// Class Methods

+(Game *)game;
+(Game *)reset;

// Important Data methods

-(void)sendDataToOpponent:(NSDictionary *)data;
-(void)handleData:(NSDictionary *)data;

// Other methods

-(Restriction)patternOfCards:(NSArray *)cards;
-(BOOL)handSatisfiesRestriction:(NSArray *)cards;

-(NSMutableArray *)generateOrderedDeck;
-(NSMutableArray *)extract13CardsFromDeck:(NSMutableArray *)deck;

@end
