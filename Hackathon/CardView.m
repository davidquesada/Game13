//
//  CardView.m
//  Hackathon
//
//  Created by David Quesada on 9/28/12.
//  Copyright (c) 2012 David Quesada. All rights reserved.
//

#import "CardView.h"
#import "MainViewController.h"
#import <QuartzCore/QuartzCore.h>

typedef enum
{
    CardShadowTypeNormal,
    CardShadowTypeNone,
    CardShadowTypeSelected
}CardShadowType;

@interface CardView ()
{
    int _cardIndex;
    BOOL _isSelected;
    UIColor *_selectionColor;
}
@end

@implementation CardView

@synthesize selectedYOffset;
@synthesize mainView;
@synthesize selectable;

-(int)cardIndex
{
    return _cardIndex;
}
-(void)setCardIndex:(int)cardIndex
{
    _cardIndex = cardIndex;
    NSString *imagename = [NSString stringWithFormat:@"%d.png", cardIndex];
    //NSLog(@"Loading image named: %@", imagename);
    UIImage *img = [UIImage imageNamed:imagename];
    imageView.image = img;
//    img.
//    self.backgroundColor = [UIColor colorWithPatternImage:img];
}

-(BOOL)isSelected
{
    return _isSelected;
}
-(void)setIsSelected:(BOOL)isSelected
{
    _isSelected = isSelected;
    if (isSelected)
    {
        [self setShadowType:CardShadowTypeSelected];
        [self.mainView cardWasSelected:self];
    }
    else
    {
        [self setShadowType:CardShadowTypeNormal];
        [self.mainView cardWasDeselected:self];
    }
    
    [self.mainView playSelectionSound:isSelected];
    
    imageView.frame = CGRectMake(0, (isSelected)?-1*self.selectedYOffset:0, imageView.frame.size.width, imageView.frame.size.height);
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        imageView = [[UIImageView alloc] init];
        [self setShadowType:CardShadowTypeNormal];
        
        self.selectedYOffset = 12.0;
        
        selectable = YES;
        _selectionColor = [UIColor whiteColor];
        
        UITapGestureRecognizer *gesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(viewTapped)];
        [imageView addGestureRecognizer:gesture];
        imageView.userInteractionEnabled = YES;
        
        [self addSubview:imageView];
//        self.backgroundColor = [UIColor colorWithHue:((arc4random() % 255) / 255.0) saturation:1 brightness:1 alpha:.7];
    }
    return self;
}

-(id)initBackWithFrame:(CGRect)frame
{
    self = [self initWithFrame:frame cardIndex:CARD_BACK];
    return self;
}

-(void)viewTapped
{
    if (self.selectable)
    {
        [UIView animateWithDuration:.18 animations:^{
            self.isSelected = !self.isSelected;
        }];
    }
}

-(id)initWithFrame:(CGRect)frame cardIndex:(int)idx
{
    self = [self initWithFrame:frame];
    if (self)
    {
        self.cardIndex = idx;
    }
    // force resize the card imageview;
    self.frame = self.frame;
    return self;
}

-(void)setShadowType:(CardShadowType)type
{
    if (type == CardShadowTypeNormal)
    {
        imageView.layer.shadowColor = [UIColor blackColor].CGColor;
        imageView.layer.shadowOpacity = .8;
        imageView.layer.shadowRadius = 6;
    } else if (type == CardShadowTypeSelected)
    {
        imageView.layer.shadowColor = self.selectionColor.CGColor;
        imageView.layer.shadowOpacity = 1;
        imageView.layer.shadowRadius = 17;
    } else if (type == CardShadowTypeNone)
    {
        imageView.layer.shadowOpacity = 0.0;
    }
}

-(UIColor *)selectionColor { return _selectionColor; }
-(void)setSelectionColor:(UIColor *)selectionColor
{
    _selectionColor = selectionColor;
    if (self.isSelected)
        imageView.layer.shadowColor = selectionColor.CGColor;
}

-(void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    [imageView setFrame:CGRectInset(self.bounds, 0, 0)];
    //imageView.layer.borderColor = [UIColor blackColor].CGColor;
    //imageView.layer.borderWidth = .01 * imageView.layer.bounds.size.height;
    //imageView.layer.cornerRadius = .035 * imageView.layer.bounds.size.height;
    imageView.layer.shadowPath = [UIBezierPath bezierPathWithRect:imageView.layer.bounds].CGPath;
    imageView.layer.shouldRasterize = YES;
    imageView.layer.rasterizationScale = [UIScreen mainScreen].scale;
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
