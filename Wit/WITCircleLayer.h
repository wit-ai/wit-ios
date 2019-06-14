//
//  CACircleLayer.h
//  Wit
//
//  Created by Willy Blandin on 21/05/2013.
//  Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
//

#import <QuartzCore/QuartzCore.h>
#import <UIKit/UIKit.h>

@interface WITCircleLayer : CALayer
@property (nonatomic, strong) NSNumber* radius;
@property (nonatomic, strong) NSNumber* lineWidth;
@property (nonatomic, strong) UIColor* fillColor;
@property (nonatomic, strong) UIColor* strokeColor;
@end
