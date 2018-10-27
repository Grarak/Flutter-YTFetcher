//
// Created by Willi Ye on 20.10.18.
//

#import <Foundation/Foundation.h>
#import "Server.h"
#import "Youtube.h"

@protocol YoutubeServerDelegate
- (void)onSuccess:(NSString *)url;

- (void)onFailure:(NSInteger)code;
@end

@interface YoutubeServer : Server
- (void)fetchSong:(Youtube *)youtube :(id <YoutubeServerDelegate>)delegate;

- (void)verifyFetchedSong:(NSString *)url :(NSString *)id :(id <YoutubeServerDelegate>)delegate;

- (void)verifyForwardedSong:(NSString *)url :(id <YoutubeServerDelegate>)delegate;
@end
