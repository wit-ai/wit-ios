//
//  WITContextSetter.h
//  Wit
//
//  Created by Aric Lasry on 10/29/14.
//  Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
//

#import <Foundation/Foundation.h>

@interface WITContextSetter : NSObject

- (NSDictionary *)contextFillup:(NSDictionary *)context;

+ (NSString *)jsonEncode:(NSDictionary *)context;

@end
