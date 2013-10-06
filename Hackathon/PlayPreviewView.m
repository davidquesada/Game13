//
//  PlayPreviewView.m
//  Hackathon
//
//  Created by David Quesada on 9/29/12.
//  Copyright (c) 2012 David Quesada. All rights reserved.
//

#import "PlayPreviewView.h"
#import "CardView.h"
#import <QuartzCore/QuartzCore.h>
@interface PlayPreviewView ()
{
    NSMutableArray *_cards; // Array containing the integer values of the cards contained in the view.
    BOOL _playIsLegal;
    UIColor *_legalGlowColor;
    UIColor *_illegalGlowColor;
    BOOL _isClearing;
    BOOL _glowShouldBeVisible;
    
    UIScrollView *scrollView;
}
@end

@implementation PlayPreviewView

@synthesize isUpdating;

-(id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        scrollView = [[UIScrollView alloc] initWithFrame:self.bounds];
        scrollView.layer.masksToBounds = NO;
        [self addSubview:scrollView];
        self.backgroundColor = [UIColor clearColor];
        _legalGlowColor = [UIColor cyanColor];
        _illegalGlowColor = [UIColor redColor];
        _cards = [[NSMutableArray alloc] init];
        _glowShouldBeVisible = YES;
    }
    return self;
}

-(void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    [scrollView setFrame:self.bounds];
}

-(NSArray *)cardIndices{
    return [_cards copy];
}

#define PREVIEW_TOP_PADDING 10.0
#define PREVIEW_SIDE_PADDING 10.0
#define PREVIEW_HSPACING -18.0
#define PREVIEW_VSPACING -20.0
#define PREVIEW_NUMCARDS_WIDE 5

-(CGFloat)cardWidth
{
    return (scrollView.frame.size.width - 2 * PREVIEW_SIDE_PADDING - (PREVIEW_NUMCARDS_WIDE - 1) * PREVIEW_HSPACING) / PREVIEW_NUMCARDS_WIDE;
}

-(CGFloat)heightOverWidthRatio
{
    return (96.0)/(72.0);
}

-(CGRect)frameForCardAtPosition:(int)index
{
    CGFloat w = [self cardWidth];
    CGFloat h = w * [self heightOverWidthRatio];
    CGFloat x = PREVIEW_SIDE_PADDING + (index % PREVIEW_NUMCARDS_WIDE) * (w + PREVIEW_HSPACING);
    CGFloat y = PREVIEW_TOP_PADDING + (index / PREVIEW_NUMCARDS_WIDE) * (h + PREVIEW_VSPACING);
    return CGRectMake(x, y, w, h);
}

-(CardView *)cardViewForCardIndex:(int)index
{
    CardView *card = [[CardView alloc] initWithFrame:CGRectZero cardIndex:index];
    card.isSelected = YES;
    card.selectable = NO;
    card.selectionColor = [self currentHighlightColor];
    return card;
}

-(UIColor *)currentHighlightColor
{
    if (self.playIsLegal)
        return _legalGlowColor;
    else
        return _illegalGlowColor;
}

-(BOOL)playIsLegal
{
    return _playIsLegal;
}

-(void)setGlowVisible:(BOOL)visible animated:(BOOL)animated
{
    CGFloat opacity = (visible) ? 1.0 : 0.0;
    
    _glowShouldBeVisible = visible;

    if (animated)
    {
        [UIView animateWithDuration:.2 animations:^{
            for (CardView *v in scrollView.subviews)
                //v.layer.shadowOpacity = opacity;
            {
                if ([v isKindOfClass:[CardView class]])
                    v.isSelected = visible;
            }
        }];
    }
    else
    {
        for (CardView *v in scrollView.subviews)
        {
           // v.layer.shadowOpacity = opacity;
            if ([v isKindOfClass:[CardView class]])
                v.isSelected = visible;
        }
    }
}

//TODO: consolidate this and the left version into one function.
-(void)clearCardsToRight
{
    CGFloat offset = 180;
    
    [self setGlowVisible:NO animated:YES];
    
    [UIView animateWithDuration:.3 animations:^{
        _isClearing = YES;
        scrollView.frame = CGRectOffset(scrollView.frame, offset, 0);
    } completion:^(BOOL finished) {
        if (finished)
        {
            _isClearing = NO;
            for (UIView *view in scrollView.subviews.copy)
            {
                [view removeFromSuperview];
            }
            [_cards removeAllObjects];
            scrollView.frame = CGRectOffset(scrollView.frame, -1 * offset, 0);
            self.isUpdating = NO;
        }
    }];
}
-(void)clearCardsToLeft
{
    CGFloat offset = -180;
    
    [self setGlowVisible:NO animated:YES];
    
    [UIView animateWithDuration:.3 animations:^{
        _isClearing = YES;
        scrollView.frame = CGRectOffset(scrollView.frame, offset, 0);
    } completion:^(BOOL finished) {
        if (finished)
        {
            _isClearing = NO;
            for (UIView *view in scrollView.subviews.copy)
            {
                [view removeFromSuperview];
            }
            [_cards removeAllObjects];
            scrollView.frame = CGRectOffset(scrollView.frame, -1 * offset, 0);
            self.isUpdating = NO;
        }
    }];
}

-(void)setPlayIsLegal:(BOOL)playIsLegal
{
    if (!(playIsLegal == _playIsLegal))
    {
        _playIsLegal = playIsLegal;
        for (CardView *view in [scrollView subviews])
        {
            if ([view isKindOfClass:[CardView class]])
            {
                if (view.selectionColor != [self currentHighlightColor])
                    view.selectionColor = [self currentHighlightColor];
            }
        }
    }
    _playIsLegal = playIsLegal;
}

-(void)setCardIndices:(NSArray *)cardIndices
{
    _cards = [cardIndices mutableCopy];
}

-(void)addCard:(int)index
{
    [self addCard:index fromScreenFrame:CGRectNull];
}
-(void)addCard:(int)index fromScreenFrame:(CGRect)oldFrame
{
    if (self.isUpdating)
        return;
    if ([_cards containsObject:@(index)])
        return;
    
    CardView *card = [self cardViewForCardIndex:index];
    
    int indexToInsertAt = 0;
    
    
    while (indexToInsertAt < _cards.count && index > [[_cards objectAtIndex:indexToInsertAt] integerValue])
        indexToInsertAt++;
    
    //card.frame = (indexToInsertAt == 0) ? [self frameForCardAtPosition:0] : [self frameForCardAtPosition:indexToInsertAt - 1];
    card.frame = [self frameForCardAtPosition:indexToInsertAt];
    card.alpha = 0.0;
    
    if (!_glowShouldBeVisible)
        card.isSelected = NO;
    
    [_cards insertObject:@(index) atIndex:indexToInsertAt];
    [scrollView insertSubview:card atIndex:indexToInsertAt];
    
    [UIView animateWithDuration:.2 animations:^{
        //card.frame = targetFrame;
        card.alpha = 1.0;
        [scrollView.subviews enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            CardView *v = obj;
            v.frame = [self frameForCardAtPosition:idx];
        }];
    }];
}

-(void)removeCard:(int)index
{
    
}
-(void)removeCard:(int)index toScreenFrame:(CGRect)newFrame
{
    if (_isClearing)
        return;
    if (self.isUpdating)
        return;
    if (![_cards containsObject:@(index)])
        return;
    CardView *card = nil;
    for (CardView *c in scrollView.subviews)
    {
        // Why the hell do these imageviews keep showing up in the scroll views?
        if ([c isKindOfClass:[UIImageView class]])
            continue;
        if (c.cardIndex == index)
        {
            card = c;
            break;
        }
    }
    
    NSMutableArray *cardsLeft = [scrollView.subviews mutableCopy];
    
    [cardsLeft removeObject:card];
    
    [UIView animateWithDuration:.2 animations:^{
        card.alpha = 0.0;
        [cardsLeft enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            CardView *v = obj;
            v.frame = [self frameForCardAtPosition:idx];
        }];
    } completion:^(BOOL finished) {
        if (finished)
        {
            [card removeFromSuperview];
        }
    }];
    
    [_cards removeObject:@(index)];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
