//
//  WitTests.m
//  WitTests
//
//  Created by patrick on 03/05/16.
//  Copyright © 2016 Willy Blandin. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <Wit/Wit.h>

@interface WitTests : XCTestCase <WitDelegate> {
    XCTestExpectation *stringInterpretedExpectation;
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
    XCTAssert([firstOutcome[@"intent"] isEqualToString:@"default_intent"], "Did not receive expected 'default_intent' intent");
    NSString *entityValue = [firstOutcome[@"entities"][@"location"] firstObject][@"value"];
    XCTAssert([entityValue isEqualToString:@"Starbucks"],@"location entity did not match expected value 'Starbucks'");
    
    [stringInterpretedExpectation fulfill];
}

- (void)testStringIntent {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
    
    [Wit sharedInstance].accessToken = @"TFMXQC4W5PKGPONSMX2LRBR3BZ44XSWK";
    [Wit sharedInstance].delegate = self;
    
    stringInterpretedExpectation = [self expectationWithDescription:@"string interpreted"];
    
    [[Wit sharedInstance] interpretString:@"How do I get to Starbucks?" customData:nil];
    
    // The test will pause here, running the run loop, until the timeout is hit
    // or all expectations are fulfilled.
    [self waitForExpectationsWithTimeout:10 handler:^(NSError *error) {
        
    }];
    
    
}


@end
