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
@property (nonatomic, strong) NSNumber* radius;
@property (nonatomic, strong) UIColor* fillColor;
@property (nonatomic, strong) UIColor* strokeColor;
@property (nonatomic, strong) NSNumber* lineWidth;

@property (nonatomic, strong) WITCircleLayer* circleLayer;
@end