//
//  WITResponse.h
//  Withm
//
//  Created by Erik Villegas on 6/30/14.
//  Copyright (c) 2014 Wit.AI. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WITResponse : NSObject

@property (nonatomic, strong) NSDictionary *entities;
@property (nonatomic, strong) NSString *intent;
@property (nonatomic, strong) NSString *body;

@end
