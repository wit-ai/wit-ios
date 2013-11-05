//
//  WitTest.m
//  Wit
//
//  Copyright (c) 2013 Willy Blandin. All rights reserved.
//

#import "Wit.h"
#import "GHAsyncTestCase.h"
#import "OCMockObject.h"
#import "AFHTTPClient.h"
#import "WITState.h"
#import "OCMockRecorder.h"
#import "OCMArg.h"

//Add the state property so it can be tested properly
@interface Wit () <RecorderDelegate, UploaderDelegate>

@property(strong, atomic) WITState *state;

- (SEL)selectorFromIntent:(NSString *)intent;

- (void)dispatchIntent:(NSString *)intent withEntities:(NSDictionary *)entities;

@end

@interface WitTest : GHAsyncTestCase
@end

@interface CommandDelegate : NSObject

- (void)addAmount:(NSArray *)entities;

- (void)verifyCredit:(NSArray *)entities;

- (void)lookup:(NSArray *)entities;

@end

@implementation CommandDelegate
- (void)addAmount:(NSArray *)entities {
}

- (void)verifyCredit:(NSArray *)entities {
}

- (void)lookup:(NSArray *)entities {
}

- (void)witOnIntentRecognized:(NSString *)intent entities:(NSArray *)entities {
}

- (void)witOnRecognitionError:(NSError *)error {
}
@end

@implementation WitTest {
    Wit *_wit;
    id _mockDelegate;
    id _mockRecorder;
    id _mockUploader;
    id _mockCommand;
}

- (void)setUp {
    [super setUp];

    _wit = [Wit sharedInstance];
    _mockDelegate = [OCMockObject niceMockForProtocol:@protocol(WitDelegate)];
    _mockCommand = [OCMockObject niceMockForClass:[CommandDelegate class]];

    _wit.delegate = _mockDelegate;
    _wit.commandDelegate = _mockCommand;
    _mockRecorder = [OCMockObject partialMockForObject:_wit.state.recorder];
    _mockUploader = [OCMockObject partialMockForObject:_wit.state.uploader];
}

- (void)tearDown {
    _wit = nil;
    _mockRecorder = nil;
    _mockUploader = nil;
    _mockDelegate = nil;
}

- (void)testStartRecording {
    [[_mockRecorder expect] record];
    [_wit captureVoiceIntent:nil];
    [_mockRecorder verify];
}

- (void)testRecorderDelegate {
    [[_mockDelegate expect] witDidStartRecording];
    [_wit recorderDidStartRecording];
    [_mockDelegate verify];
}

- (void)testOnFinishRecordingCallUploader {
    NSURL *testUrl = [NSURL fileURLWithPath:@"Test"];
    [[_mockUploader expect] uploadSampleWithURL:testUrl];
    [_wit recorderDidFinishRecording:testUrl];
    [_mockUploader verify];
}

- (void)testOnUploadResponse {
    [[_mockDelegate expect] witOnIntentRecognized:[OCMArg checkWithBlock:^BOOL(id value) {
        return [value isEqualToString:@"lookup"];
    }]
                                         entities:[OCMArg checkWithSelector:@selector(isEqualToArray:)
                                                                   onObject:@[]]];

    //Check that the selector is automatically called by the SDK.
    [[_mockCommand expect] lookup:[OCMArg checkWithSelector:@selector(isEqualToArray:)
                                                   onObject:@[]]];

    [_wit uploaderDidGetResponse:@"{\n"
            "    \"msg_id\": \"OTk5Nzc\",\n"
            "    \"outcome\": {\n"
            "        \"intent\": \"lookup\",\n"
            "        \"slots\": [],\n"
            "        \"confidence\": 0.9950222874593222\n"
            "    }\n"
            "}"];
    [_mockDelegate verify];
    [_mockCommand verify];
}

- (void)testOnUploadResponseWitReturnError {
    [[_mockDelegate expect] witOnRecognitionError:[OCMArg checkWithBlock:^BOOL(id value) {
        return [[[value userInfo] valueForKey:NSLocalizedDescriptionKey] isEqualToString:@"Wit returned an analysis error (234) : error message"];
    }]];

    [_wit uploaderDidGetResponse:@"{\"msg-id\":\"ABCDEFGHIJ\", \"error\": {\"code\":234,\"message\":\"error message\"}}"];
    [_mockDelegate verify];
}

- (void)testOnUploadResponseGenerateError {
    [[_mockDelegate expect] witOnRecognitionError:[OCMArg any]];
    [_wit uploaderDidGetResponse:@"incorrect JSON Response"];
    [_mockDelegate verify];
}

- (void)testOnError {
    [[_mockDelegate expect] witOnRecognitionError:[OCMArg any]];
    [_wit recorderOnError:nil];
}

- (void)testCancelCallCancelFromRecorder {
    [[_mockRecorder expect] cancel];
    [_wit cancel];
}

- (void)testSelectorFromIntent {
    SEL selectorResult = [_wit selectorFromIntent:@"testString"];
    GHAssertEqualStrings(NSStringFromSelector(selectorResult), @"teststring:", @"Selector must have been correctly generated");
    selectorResult = [_wit selectorFromIntent:@"test String"];
    GHAssertEqualStrings(NSStringFromSelector(selectorResult), @"testString:", @"Selector must have been correctly generated");
    selectorResult = [_wit selectorFromIntent:@"test_string"];
    GHAssertEqualStrings(NSStringFromSelector(selectorResult), @"testString:", @"Selector must have been correctly generated");
    selectorResult = [_wit selectorFromIntent:@"TEST34563456STRING"];
    GHAssertEqualStrings(NSStringFromSelector(selectorResult), @"test34563456String:", @"Selector must have been correctly generated");
    selectorResult = [_wit selectorFromIntent:@"test!@#$%^&*()_-+=}]1{[\\|';:/?.>,<`~string"];
    GHAssertEqualStrings(NSStringFromSelector(selectorResult), @"test1String:", @"Selector must have been correctly generated");
}

- (void)testCallSelectorInDelegate {
    [[_mockCommand expect] addAmount:[OCMArg checkWithSelector:@selector(isEqualToDictionary:)
                                                      onObject:@{}]];
    [[_mockCommand expect] verifyCredit:[OCMArg checkWithSelector:@selector(isEqualToDictionary:)
                                                         onObject:@{@"amount" : @"200", @"currency" : @"$", @"category" : @"pet"}]];
    [_wit dispatchIntent:@"add amount" withEntities:@{}];
    [_wit dispatchIntent:@"verify_credit" withEntities:@{@"amount" : @"200", @"currency" : @"$", @"category" : @"pet"}];
    [_mockCommand verify];
}
@end
