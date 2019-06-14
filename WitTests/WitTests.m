//
//  WitTests.m
//  WitTests
//
//  Created by patrick on 03/05/16.
//  Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
//

#import <XCTest/XCTest.h>
#import <Wit/Wit.h>

@interface WitTests : XCTestCase <WitDelegate> {
    XCTestExpectation *stringInterpretedExpectation;
    XCTestExpectation *converseExpectation;
    XCTestExpectation *converseErrorExpectation;
}


@end

@implementation WitTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)witDidGraspIntent:(NSArray *)outcomes messageId:(NSString *)messageId customData:(id) customData error:(NSError*)error {
    XCTAssert(!error, @"Wit grasp error occured");
    NSDictionary *firstOutcome = [outcomes firstObject];
    XCTAssert([firstOutcome[@"intent"] isEqualToString:@"default_intent"], @"Did not receive expected 'default_intent' intent");
    NSString *entityValue = [firstOutcome[@"entities"][@"location"] firstObject][@"value"];
    XCTAssert([entityValue isEqualToString:@"Starbucks"],@"location entity did not match expected value 'Starbucks'");
    
    [stringInterpretedExpectation fulfill];
}

- (WitSession *) didReceiveAction:(NSString *)action entities:(NSDictionary *)entities witSession:(WitSession *)session confidence:(double)confidence {
    dispatch_sync(dispatch_get_main_queue(), ^{
        XCTAssert([action isEqualToString:@"get_location"], @"did not receive expected action");
        XCTAssert(entities.count == 2, @"did not receive expected number of entities");
        XCTAssert(session != nil, @"got no session information, error");
        session.context = @{@"reply" : @"done"};
    });

    return session;
}

- (WitSession *)didReceiveMessage:(NSString *)message quickReplies:(NSArray *)quickReplies witSession:(WitSession *)session confidence:(double)confidence {
    XCTAssert([message isEqualToString:@"Test OK done"], @"did not receive expected message");
    XCTAssert(quickReplies.count == 2, @"did not receive expected number of quickreplies");
    XCTAssert(session != nil, @"got no session information, error");
    return session;
}

- (void)didStopSession:(WitSession *)session {
    XCTAssert(session != nil, @"got no session information, error");
    [converseExpectation fulfill];
    
}

- (void)didReceiveConverseError:(NSError *)error witSession:(WitSession *)session {
    XCTAssert(session != nil, @"got no session information, error");
    XCTAssert(error != nil, @"got no error information, error");
    [converseErrorExpectation fulfill];
    
}
- (void)testStringIntent {
    [Wit sharedInstance].accessToken = @"TFMXQC4W5PKGPONSMX2LRBR3BZ44XSWK";
    [Wit sharedInstance].delegate = self;
    
    stringInterpretedExpectation = [self expectationWithDescription:@"string interpreted"];
    
    [[Wit sharedInstance] interpretString:@"How do I get to Starbucks?" customData:nil];
    
    // The test will pause here, running the run loop, until the timeout is hit
    // or all expectations are fulfilled.
    [self waitForExpectationsWithTimeout:10 handler:^(NSError *error) {
        
    }];
    
}

- (void)testConverse {
    
    [Wit sharedInstance].accessToken = @"CDK44N5OBSB7WRDQ7ZQA53A6GK3ZJGVR";
    [Wit sharedInstance].delegate = self;
    
    converseExpectation = [self expectationWithDescription:@"gotGetLocation"];
    WitSession *session = [[WitSession alloc] initWithSessionID:[[NSUUID UUID] UUIDString]];
    [[Wit sharedInstance] converseWithString:@"Where is the nearest Starbucks?" witSession:session];
    
    // The test will pause here, running the run loop, until the timeout is hit
    // or all expectations are fulfilled.
    [self waitForExpectationsWithTimeout:15 handler:^(NSError *error) {
        
    }];
    
}

- (void)testConverseError {
    
    [Wit sharedInstance].accessToken = @"CDK44N5OBSB7WRDQ7ZQA53A6GK3ZJGVRZ"; //wrong access token to test converse error
    [Wit sharedInstance].delegate = self;
    
    converseErrorExpectation = [self expectationWithDescription:@"waitingForError"];
    WitSession *session = [[WitSession alloc] initWithSessionID:[[NSUUID UUID] UUIDString]];
    [[Wit sharedInstance] converseWithString:@"Where is the nearest Starbucks?" witSession:session];
    
    // The test will pause here, running the run loop, until the timeout is hit
    // or all expectations are fulfilled.
    [self waitForExpectationsWithTimeout:15 handler:^(NSError *error) {
        
    }];
    
}


@end
