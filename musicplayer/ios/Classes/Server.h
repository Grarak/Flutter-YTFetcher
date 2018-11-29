//
// Created by Willi Ye on 22.10.18.
//

#import <Foundation/Foundation.h>
#import "Request.h"
#import "Status.h"

#define API_VERSION @"v1"

@protocol ServerDelegate <NSObject>
@optional
- (BOOL)onConnect:(Request *)request :(NSInteger)status :(NSString *) url;

@required
- (void)onSuccess:(Request *)request :(NSString *)response :(NSDictionary *)headers;

- (void)onError:(Request *)request :(NSInteger)status :(NSError *)error;
@end

@interface Server : NSObject {
    NSMutableArray<Request *> *_requests;
    NSString *_url;
}

- (id)initWithUrl:(NSString *)url;

- (void)setUrl:(NSString *)url;

- (NSString *)getApiUrl:(NSString *)path;

- (void)get:(NSString *)path :(id <ServerDelegate>)delegate;

- (void)getUrl:(NSString *)url :(id <ServerDelegate>)delegate;

- (void)post:(NSString *)path :(NSString *)data :(id <ServerDelegate>)delegate;

- (void)postUrl:(NSString *)url :(NSString *)data :(id <ServerDelegate>)delegate;

- (void)close;
@end
