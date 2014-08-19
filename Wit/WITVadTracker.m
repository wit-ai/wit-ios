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
    // A response has been received, this is where we initialize the instance var you created
    // so that we can append data to it in the didReceiveData method
    // Furthermore, this method is called each time there is a redirect so reinitializing it
    // also serves to clear it
    self._responseData = [[NSMutableData alloc] init];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    // Append the new data to the instance variable you declared
    [self._responseData appendData:data];
    NSLog(@"recevied data from the vad tracker: %@", self._responseData);
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection
                  willCacheResponse:(NSCachedURLResponse*)cachedResponse {
    // Return nil to indicate not necessary to store a cached response for this connection
    return nil;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    // The request is complete and data has been received
    // You can parse the stuff in your instance variable now
    
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    // The request has failed for some reason!
    // Check the error var
    NSLog(@"WITVadTracker error: %@", error);
}

-(void) dealloc {
        NSLog(@"Clean WITVadTracker");
}

@end
