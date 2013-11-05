//
//  CACircleLayer.m
//  Wit
//
//  Created by Willy Blandin on 21/05/2013.
//  Copyright (c) 2013 Willy Blandin. All rights reserved.
//

#import "WITCircleLayer.h"

@implementation WITCircleLayer
@dynamic radius, lineWidth, strokeColor, fillColor, opacity;

+ (BOOL)needsDisplayForKey:(NSString *)key {
    if ([key isEqualToString:@"radius"]
        || [key isEqualToString:@"lineWidth"]
        || [key isEqualToString:@"strokeColor"]
        || [key isEqualToString:@"fillColor"]
        || [key isEqualToString:@"opacity"]) {
        return YES;
    }
    return [super needsDisplayForKey:key];
}

- (void)drawInContext:(CGContextRef)ctx {
    [super drawInContext:ctx];
    
    CGRect rect = CGContextGetClipBoundingBox(ctx);

    CGFloat radius = (self.radius.floatValue - (self.lineWidth.floatValue || 0));
    UIBezierPath* bezier = [UIBezierPath bezierPathWithArcCenter:CGPointMake(rect.size.width/2, rect.size.height/2)
                                                          radius:radius
                                                      startAngle:0 endAngle:2*M_PI clockwise:NO];
    
    CGPathRef path = bezier.CGPath;
    
    CGContextSetFillColorWithColor(ctx, self.fillColor.CGColor);
    CGContextAddPath(ctx, path);

    if (self.fillColor) {
        CGContextFillPath(ctx);
    }
    
    if (self.strokeColor) {
        if (self.lineWidth) {
            CGContextSetLineWidth(ctx, self.lineWidth.floatValue);
        }
        
        CGContextSetStrokeColorWithColor(ctx, self.strokeColor.CGColor);
        CGContextAddPath(ctx, path);
        CGContextStrokePath(ctx);
    }
}

#pragma mark - Lifecycle
- (id)init {
    self = [super init];
    
    if (self) {
    }
    
    return self;
}

- (void)dealloc {
}
@end
