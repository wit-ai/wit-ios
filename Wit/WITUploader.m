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

@interface WITUploader ()
@property (atomic) BOOL requestEnding;

// queue used to send audio chunks in HTTP body
// will be suspended / resumed according to stream availability
@property (atomic) NSOperationQueue* q;
@end

@implementation WITUploader {
    NSString* kWitSpeechURL;
    NSOutputStream *outStream;
    NSInputStream *inStream;
    NSDate *start; // used to time requests
    NSURLConnection *currentConnection;
}
@synthesize requestEnding, q;

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
    currentConnection = [NSURLConnection connectionWithRequest:req delegate:self];
    
    [currentConnection start];
    
    return YES;
}
-(void)sendChunk:(NSData*)chunk {
    debug(@"Adding operation %u bytes", (unsigned int)[chunk length]);
    [q addOperationWithBlock:^{
        if (outStream) {
            [q setSuspended:YES];

            debug(@"Uploading %u bytes", (unsigned int)[chunk length]);
            [outStream write:[chunk bytes] maxLength:[chunk length]];
        }

        NSUInteger cnt = q.operationCount;
        debug(@"Operation count: %d", cnt);
        if (requestEnding && cnt <= 1) {
            [self cleanUp];
        }
    }];
}

- (void) cleanUp {
    debug(@"Cleaning up");
    if (outStream) {
        debug(@"Cleaning up output stream");
        [outStream close];
        [outStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        outStream = nil;
        inStream = nil;

        start = [NSDate date];
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

#pragma mark - NSURLConnectionDataDelegate methods

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    
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
}

#pragma mark - NSURLConnectionDelegate methods

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    
    debug(@"Got connection error: %@", connectionError.localizedDescription);
    [self.delegate gotResponse:nil error:error];
}

#pragma mark - NSStreamDelegate
-(void)stream:(NSStream *)s handleEvent:(NSStreamEvent)eventCode {
    switch (eventCode) {
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
        case NSStreamEventErrorOccurred:
            debug(@"Stream error occurred");
            [self cleanUp];
            break;
        case NSStreamEventEndEncountered:
            debug(@"Stream end encountered");
            [self cleanUp];
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
