//
//  WITCircleView.h
//  Wit
//
//  Created by Willy Blandin on 28/05/2013.
//  Copyright (c) 2013 Willy Blandin. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WITCircleLayer.h"

@interface WITCircleView : UIView
@property NSNumber* radius;
@property UIColor* fillColor;
@property UIColor* strokeColor;
@property NSNumber* lineWidth;

@property (strong) WITCircleLayer* circleLayer;
@end