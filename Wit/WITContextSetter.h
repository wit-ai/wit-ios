//
//  WITContextSetter.h
//  Wit
//
//  Created by Aric Lasry on 10/29/14.
//  Copyright (c) 2014 Willy Blandin. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WITContextSetter : NSObject

- (NSDictionary *)contextFillup:(NSDictionary *)context;

+ (NSString *)jsonEncode:(NSDictionary *)context;

@end
