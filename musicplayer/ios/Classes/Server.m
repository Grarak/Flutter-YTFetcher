//
// Created by Willi Ye on 22.10.18.
//

#import "Server.h"

@interface ServerDelegate : NSObject <RequestDelegate>

- (id)initWithDelegate:(id <ServerDelegate>)delegate;

@property(nonatomic, readonly) id <ServerDelegate> delegate;

@end

@implementation ServerDelegate
- (id)initWithDelegate:(id <ServerDelegate>)delegate {
    self = [super init];
    if (self) {
        _delegate = delegate;
    }
    return self;
}

- (BOOL)onConnect:(Request *)request :(NSInteger)status :(NSString *)url {
    if (_delegate && [_delegate respondsToSelector:@selector(onConnect:: :)]) {
        return [_delegate onConnect:request :status :url];
    }
    return YES;
}

- (void)onSuccess:(Request *)request :(NSInteger)status :(NSDictionary *)headers :(NSData *)response {
    if (status == 200) {
        if (_delegate) {
            [_delegate onSuccess:request :[[NSString alloc] initWithData:response encoding:NSUTF8StringEncoding] :headers];
        }
    } else {
        if (_delegate) {
            [_delegate onError:request :[Status getStatusCode:response] :nil];
        }
    }
}

- (void)onFailure:(Request *)request :(NSError *)error {
    if (_delegate) {
        [_delegate onError:request :ServerOffline :error];
    }
}
@end

@implementation Server

- (id)initWithUrl:(NSString *)url {
    self = [super init];
    if (self) {
        _requests = [NSMutableArray array];
        _url = url;
    }
    return self;
}

- (void)setUrl:(NSString *)url {
    _url = url;
}

- (NSString *)getApiUrl:(NSString *)path {
    return [NSString stringWithFormat:@"%@/api/%@/%@", _url, API_VERSION, path];
}

- (void)get:(NSString *)path :(id <ServerDelegate>)delegate {
    [self getUrl:[self getApiUrl:path] :delegate];
}

- (void)getUrl:(NSString *)url :(id <ServerDelegate>)delegate {
    Request *request = [[Request alloc] initWithOptions:url :nil :nil
            :[[ServerDelegate alloc] initWithDelegate:delegate]];
    @synchronized (self) {
        [_requests addObject:request];
    }
}

- (void)post:(NSString *)path :(NSString *)data :(id <ServerDelegate>)delegate {
    [self postUrl:[self getApiUrl:path] :data :delegate];
}

- (void)postUrl:(NSString *)url :(NSString *)data :(id <ServerDelegate>)delegate {
    Request *request = [[Request alloc] initWithOptions:url :@"application/json" :data
            :[[ServerDelegate alloc] initWithDelegate:delegate]];
    @synchronized (self) {
        [_requests addObject:request];
    }
}

- (void)close {
    @synchronized (self) {
        for (Request *request in _requests) {
            [request close];
        }
    }
}

@end
