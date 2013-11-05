//
//  WITCircleView.m
//  Wit
//
//  Created by Willy Blandin on 28/05/2013.
//  Copyright (c) 2013 Willy Blandin. All rights reserved.
//

#import "WITCircleView.h"

@interface WITCircleView ()
@end

@implementation WITCircleView
#pragma mark - Layout
- (void)layoutSublayersOfLayer:(CALayer *)layer {
    if (layer == self.layer) {
    }
}

#pragma mark - Lifecycle
- (id)init {
    self = [super init];
    if (self) {
        self.circleLayer = (WITCircleLayer*)self.layer;

        // retinarize
        if ([self respondsToSelector:@selector(setContentScaleFactor:)]) {
            self.contentScaleFactor = [[UIScreen mainScreen] scale];
        }
    }
    return self;
}

+ (Class)layerClass {
    return [WITCircleLayer class];
}

#pragma mark - Getters and setters
- (NSNumber*)radius {
    return self.circleLayer.radius;
}
- (void)setRadius:(NSNumber *)radius {
    self.circleLayer.radius = radius;
}
- (UIColor *)fillColor {
    return self.circleLayer.fillColor;
}
- (void)setFillColor:(UIColor *)color {
    self.circleLayer.fillColor = color;
}
- (NSNumber *)lineWidth {
    return self.circleLayer.lineWidth;
}
- (void)setLineWidth:(NSNumber *)lineWidth {
    self.circleLayer.lineWidth = lineWidth;
}
- (void)setStrokeColor:(UIColor *)strokeColor {
    self.circleLayer.strokeColor = strokeColor;
}
- (UIColor *)strokeColor {
    return self.circleLayer.strokeColor;
}
@end
