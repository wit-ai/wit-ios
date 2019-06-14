//
//  WitSession.m
//  Wit
//
//  Created by patrick on 20/02/2017.
//  Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
//

#import "WitSession.h"

@implementation WitSession


- (instancetype)initWithSessionID: (NSString *) sessionID
{
    self = [super init];
    if (self) {
        _sessionID = sessionID;
    }
    return self;
}

- (NSString *)debugDescription
{
    return [NSString stringWithFormat:@"<%@: %p> sessionID: %@, context: %@, customData: %@", [self class], self, self.sessionID, self.context, self.customData];
}
@end
