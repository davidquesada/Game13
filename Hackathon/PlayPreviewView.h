//
//  PlayPreviewView.h
//  Hackathon
//
//  Created by David Quesada on 9/29/12.
//  Copyright (c) 2012 David Quesada. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PlayPreviewView : UIView

@property NSArray *cardIndices;
@property BOOL playIsLegal;
@property BOOL isUpdating;

-(void)setGlowVisible:(BOOL)visible animated:(BOOL)animated;

-(void)addCard:(int)index;
-(void)addCard:(int)index fromScreenFrame:(CGRect)oldFrame;

-(void)removeCard:(int)index;
-(void)removeCard:(int)index toScreenFrame:(CGRect)newFrame;

-(void)clearCardsToRight;
-(void)clearCardsToLeft;

@end
