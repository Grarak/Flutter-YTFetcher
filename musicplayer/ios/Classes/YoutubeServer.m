//
// Created by Willi Ye on 20.10.18.
//

#import "YoutubeServer.h"

@interface FetchDelegate : NSObject <ServerDelegate>
- (id)initWithDelegate:(YoutubeServer *)server :(id <YoutubeServerDelegate>)delegate;

@property(nonatomic) YoutubeServer *server;

@property(nonatomic) id <YoutubeServerDelegate> serverDelegate;
@end

@implementation FetchDelegate
- (id)initWithDelegate:(YoutubeServer *)server :(id <YoutubeServerDelegate>)delegate {
    self = [super init];
    if (self) {
        _server = server;
        _serverDelegate = delegate;
    }
    return self;
}

- (void)onSuccess:(Request *)request :(NSString *)response :(NSDictionary *)headers {
    NSString *ytfetcherId = headers[@"ytfetcher-id"];
    if (ytfetcherId) {
        [_server verifyFetchedSong:response :ytfetcherId :_serverDelegate];
    } else {
        [_serverDelegate onSuccess:response];
    }
}

- (void)onError:(Request *)request :(NSInteger)status :(NSError *)error {
    [_serverDelegate onFailure:ServerOffline];
}
@end

@interface VerifyDelegate : NSObject <ServerDelegate>
- (id)initWithDelegate:(YoutubeServer *)server :(NSString *)youtubeId :(NSString *)url :(id <YoutubeServerDelegate>)delegate;

@property(readonly, nonatomic) NSString *youtubeId;

@property(readonly, nonatomic) NSString *url;

@property(nonatomic) YoutubeServer *server;

@property(nonatomic) id <YoutubeServerDelegate> delegate;
@end

@implementation VerifyDelegate
- (id)initWithDelegate:(YoutubeServer *)server :(NSString *)youtubeId :(NSString *)url :(id <YoutubeServerDelegate>)delegate {
    self = [super init];
    if (self) {
        _youtubeId = youtubeId;
        _url = url;
        _server = server;
        _delegate = delegate;
    }
    return self;
}

- (BOOL)onConnect:(Request *)request :(NSInteger)status :(NSString *)url {
    if (status >= 200 && status < 300) {
        [_delegate onSuccess:url];
    } else {
        [_server verifyForwardedSong:[self buildUrl] :_delegate];
    }
    return false;
}

- (NSString *)URLEncodeStringFromString:(NSString *)text {
    static CFStringRef charset = CFSTR("!@#$%&*()+'\";:=,/?[] ");
    CFStringRef str = (__bridge CFStringRef) text;
    CFStringEncoding encoding = kCFStringEncodingUTF8;
    return (NSString *) CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(NULL, str, NULL, charset, encoding));
}

- (NSString *)buildUrl {
    return [NSString stringWithFormat:@"%@%@&url=%@",
                                      [_server getApiUrl:@"youtube/get?id="],
                                      [self URLEncodeStringFromString:_youtubeId],
                                      [self URLEncodeStringFromString:_url]];
}

- (void)onSuccess:(Request *)request :(NSString *)response :(NSDictionary *)headers {
}

- (void)onError:(Request *)request :(NSInteger)status :(NSError *)error {
    [_server verifyForwardedSong:[self buildUrl] :_delegate];
}
@end

@interface VerifyForwardedDelegate : NSObject <ServerDelegate>
- (id)initWithDelegate:(NSString *)url :(id <YoutubeServerDelegate>)delegate;

@property(readonly, nonatomic) NSString *url;

@property(nonatomic) id <YoutubeServerDelegate> delegate;
@end

@implementation VerifyForwardedDelegate
- (id)initWithDelegate:(NSString *)url :(id <YoutubeServerDelegate>)delegate {
    self = [super init];
    if (self) {
        _url = url;
        _delegate = delegate;
    }
    return self;
}

- (BOOL)onConnect:(Request *)request :(NSInteger)status :(NSString *)url {
    if (status >= 200 && status < 300) {
        [_delegate onSuccess:url];
    } else {
        [_delegate onFailure:ServerOffline];
    }
    return NO;
}

- (void)onSuccess:(Request *)request :(NSString *)response :(NSDictionary *)headers {
}

- (void)onError:(Request *)request :(NSInteger)status :(NSError *)error {
    [_delegate onFailure:ServerOffline];
}
@end

@implementation YoutubeServer
- (void)fetchSong:(Youtube *)youtube :(id <YoutubeServerDelegate>)delegate {
    [self post:@"youtube/fetch" :[youtube to_string] :[[FetchDelegate alloc] initWithDelegate:self :delegate]];
}

- (void)verifyFetchedSong:(NSString *)url :(NSString *)id :(id <YoutubeServerDelegate>)delegate {
    [self getUrl:url :[[VerifyDelegate alloc] initWithDelegate:self :id :url :delegate]];
}

- (void)verifyForwardedSong:(NSString *)url :(id <YoutubeServerDelegate>)delegate {
    [self getUrl:url :[[VerifyForwardedDelegate alloc] initWithDelegate:url :delegate]];
}
@end
