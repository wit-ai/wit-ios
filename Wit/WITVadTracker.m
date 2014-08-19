//
//  WITVadTracker.m
//  Wit
//
//  Created by Aric Lasry on 8/14/14.
//  Copyright (c) 2014 Willy Blandin. All rights reserved.
//

#import "WitPrivate.h"
#import "WITVadTracker.h"

@interface WITVadTracker ()
@property NSMutableData *_responseData;
@end

@implementation WITVadTracker {
    NSURLConnection *conn;
}

-(void)track:(NSString *)status withMessageId:(NSString *)messageId withToken:(NSString *)token {
    NSString *url = [[NSString alloc] initWithFormat:@"%@/speech/vad?message-id=%@", kWitAPIUrl, messageId];
    NSLog(@"here is the final url %@ and the token: %@", url, token);
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    request.HTTPMethod = @"PUT";
    [request setValue:[NSString stringWithFormat:@"Bearer %@", token] forHTTPHeaderField:@"Authorization"];
    conn = [[NSURLConnection alloc] initWithRequest:request delegate:self];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection
                  willCacheResponse:(NSCachedURLResponse*)cachedResponse {
    // Return nil to indicate not necessary to store a cached response for this connection
    return nil;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    NSLog(@"WITVadTracker error: %@", error);
}

-(void) dealloc {
        NSLog(@"Clean WITVadTracker");
}

@end
