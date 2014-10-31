//
//  WITContextSetter.h
//  Wit
//
//  Created by Aric Lasry on 10/29/14.
//  Copyright (c) 2014 Willy Blandin. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WITContextSetter : NSObject

-(void)contextFillup:(NSMutableDictionary *)context;

+(NSString *)jsonEncode: (NSMutableDictionary *)context;

@end
