//
// Created by Willi Ye on 20.10.18.
//

#import <Foundation/Foundation.h>

@class Request;

@protocol RequestDelegate <NSObject>
@optional
- (BOOL)onConnect:(Request *)request :(NSInteger)status :(NSString *)url;

@required
- (void)onSuccess:(Request *)request :(NSInteger)status :(NSDictionary *)headers :(NSData *)response;

- (void)onFailure:(Request *)request :(NSError *)error;
@end

@interface Request : NSObject <NSURLSessionDataDelegate> {
    NSURLSessionDataTask *_dataTask;
}
@property(readonly, nonatomic) id <RequestDelegate> requestDelegate;

@property(nonatomic) NSString *url;

@property(readonly, nonatomic) NSString *data;

@property(readonly, nonatomic) NSString *contentType;

@property(readonly, nonatomic) NSHTTPURLResponse *response;

@property(readonly, nonatomic) BOOL cancelled;

- (id)initWithOptions:(NSString *)url :(nullable NSString *)contentType :(nullable NSString *)data
        :(id <RequestDelegate>)delegate;

- (void)close;
@end
