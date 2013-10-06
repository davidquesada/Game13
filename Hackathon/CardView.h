//
//  CardView.h
//  Hackathon
//
//  Created by David Quesada on 9/28/12.
//  Copyright (c) 2012 David Quesada. All rights reserved.
//

#import <UIKit/UIKit.h>

#define CARD_BACK 80

@class MainViewController;
@interface CardView : UIView
{
    UIImageView *imageView;
}

@property int cardIndex;
@property BOOL isSelected;
@property BOOL selectable;
@property CGFloat selectedYOffset;
@property MainViewController *mainView;
@property UIColor *selectionColor;

-(id)initWithFrame:(CGRect)frame cardIndex:(int)idx;
-(id)initBackWithFrame:(CGRect)frame;

@end
