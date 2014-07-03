//
//  Uploader.m
//  Wit
//
//  Created by Willy Blandin on 12. 9. 3..
//  Copyright (c) 2012년 Willy Blandin. All rights reserved.
//

#import "WitPrivate.h"
#import "WITUploader.h"
#import "WITState.h"
#import "util.h"


@implementation WITUploader {
    NSString* kWitSpeechURL;
    NSOutputStream *outStream;
    NSInputStream *inStream;
    NSDate *start; // used to time requests
    

    // queue used to send audio chunks in HTTP body
    // will be suspended / resumed according to stream availability
    NSOperationQueue* q;
    BOOL requestEnding;
}

#pragma mark - Stream networking
-(BOOL)startRequestWithContext:(NSDictionary *)context {
    requestEnding = NO;
    NSString* token = [[WITState sharedInstance] accessToken];

    // CF wiring
    CFWriteStreamRef writeStream;
    CFReadStreamRef readStream;
    readStream = NULL;
    writeStream = NULL;
    CFStreamCreateBoundPair(NULL, &readStream, &writeStream, 65536);

    // convert to NSStream and set as property
    inStream = CFBridgingRelease(readStream);
    outStream = CFBridgingRelease(writeStream);

    [outStream setDelegate:self];
    [outStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [outStream open];

    NSString* urlString;

    // build HTTP Request
    // if context, add to URL
    if (context != nil) {
        NSError* serializationError;
        NSData *data = [NSJSONSerialization dataWithJSONObject:context
                                                       options:0
                                                         error:&serializationError];
        NSString *encoded = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        encoded = urlencodeString(encoded);
        urlString = [NSString stringWithFormat:@"%@&context=%@", kWitSpeechURL, encoded];
    } else {
        urlString = kWitSpeechURL;
    }

    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]];
    [req setHTTPMethod:@"POST"];
    [req setCachePolicy:NSURLCacheStorageNotAllowed];
    [req setTimeoutInterval:15.0];
    [req setHTTPBodyStream:inStream];
    [req setValue:[NSString stringWithFormat:@"Bearer %@", token] forHTTPHeaderField:@"Authorization"];
    [req setValue:@"wit/ios" forHTTPHeaderField:@"Content-type"];
    [req setValue:@"chunked" forHTTPHeaderField:@"Transfer-encoding"];
    [req setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    debug(@"HTTP %@ %@", req.HTTPMethod, urlString);

    // send HTTP request
    [NSURLConnection sendAsynchronousRequest:req
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                               if (WIT_DEBUG) {
                                   NSHTTPURLResponse* httpResp = (NSHTTPURLResponse*)response;
                                   NSTimeInterval t = [[NSDate date] timeIntervalSinceDate:start];
                                   NSLog(@"Wit response %d (%f s) %@",
                                         [httpResp statusCode],
                                         t,
                                         [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
                               }

                               if (connectionError) {
                                   debug(@"Got connection error: %@", connectionError.localizedDescription);
                                   [self.delegate gotResponse:nil error:connectionError];
                                   return;
                               }

                               NSError *serializationError;
                               NSDictionary *object = [NSJSONSerialization JSONObjectWithData:data
                                                                                      options:0
                                                                                        error:&serializationError];
                               if (serializationError) {
                                   [self.delegate gotResponse:nil error:serializationError];
                                   return;
                               }

                               if (object[@"error"]) {
                                   debug(@"Wit error: %@", object[@"error"]);
                                   NSDictionary *infos = @{NSLocalizedDescriptionKey: object[@"error"],
                                                           kWitKeyError: object[@"code"]};
                                   [self.delegate gotResponse:nil
                                                        error:[NSError errorWithDomain:@"WitProcessing"
                                                                                  code:1
                                                                              userInfo:infos]];
                                   return;
                               }

                               [self.delegate gotResponse:object error:nil];
                           }];

    return YES;
}
-(void)sendChunk:(NSData*)chunk {
    if (outStream.hasSpaceAvailable && q.isSuspended) {
        [q setSuspended:NO];
    }
    [q addOperationWithBlock:^{
        if (outStream) {
            debug(@"Uploading %u bytes", (unsigned int)[chunk length]);
            [outStream write:[chunk bytes] maxLength:[chunk length]];
            [q setSuspended:YES];
            if (requestEnding && q.operationCount <= 1) {
                [self cleanUp];
            }
        }
    }];
}

- (void) cleanUp {
    if (outStream) {
        start = [NSDate date];
        [outStream close];
        [outStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        outStream = nil;
        inStream = nil;
    }

    [q cancelAllOperations];
    [q setSuspended:NO];
}

-(void)endRequest {
    debug(@"Ending request");
    requestEnding = YES;
    if (q.operationCount <= 0) {
        [self cleanUp];
    }
}

#pragma mark - NSStreamDelegate
-(void)stream:(NSStream *)s handleEvent:(NSStreamEvent)eventCode {
    switch (eventCode) {
        case NSStreamEventErrorOccurred:
            debug(@"Stream error occured");
            break;
        case NSStreamEventOpenCompleted:
            debug(@"Stream open completed");
            break;
        case NSStreamEventHasBytesAvailable:
            debug(@"Stream has bytes available");
            break;
        case NSStreamEventHasSpaceAvailable:
            if (s == outStream) {
//                debug(@"outStream has space, resuming dispatch");
                if ([q isSuspended]) {
                    [q setSuspended:NO];
                }
            }
            break;
        case NSStreamEventEndEncountered:
            debug(@"Stream end encountered");
            break;
        case NSStreamEventNone:
            debug(@"Stream event none");
            break;
    }
}

#pragma mark - Lifecycle
+(WITUploader*)sharedInstance {
    static WITUploader *instance;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        instance = [[WITUploader alloc] init];
    });

    return instance;
}
-(id)init {
    self = [super init];
    if (self) {
        q = [[NSOperationQueue alloc] init];
        [q setMaxConcurrentOperationCount:1];
        kWitSpeechURL = [NSString stringWithFormat: @"https://api.wit.ai/speech?v=%@", kWitAPIVersion];
    }
    return self;
}
-(void)dealloc {
    if (outStream) {
        [outStream close];
        outStream = nil;
    }
    if (inStream) {
        [inStream close];
        inStream = nil;
    }
    if (q) {
        [q cancelAllOperations];
    }
}

@end
