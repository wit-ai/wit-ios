//
//  CACircleLayer.h
//  Wit
//
//  Created by Willy Blandin on 21/05/2013.
//  Copyright (c) 2013 Willy Blandin. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import <UIKit/UIKit.h>

@interface WITCircleLayer : CALayer
@property (nonatomic) NSNumber* radius;
@property (nonatomic) NSNumber* lineWidth;
@property (strong) UIColor* fillColor;
@property (strong) UIColor* strokeColor;
@end
