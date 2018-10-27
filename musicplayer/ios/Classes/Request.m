//
// Created by Willi Ye on 20.10.18.
//

#import "Request.h"

@implementation Request

- (id)initWithOptions:(NSString *)url :(nullable NSString *)contentType :(nullable NSString *)data
        :(id <RequestDelegate>)delegate {
    self = [super init];
    if (self) {
        _url = url;
        _requestDelegate = delegate;
        _data = data;
        _contentType = contentType;

        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
        NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:nil];
        _dataTask = [session dataTaskWithRequest:[self buildRequest]];
        [_dataTask resume];
    }
    return self;
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler {
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
    _response = httpResponse;
    if (![_requestDelegate respondsToSelector:@selector(onConnect:: :)]
            || [_requestDelegate onConnect:self :[httpResponse statusCode] :_url]) {
        _cancelled = false;
        completionHandler(NSURLSessionResponseAllow);
    } else {
        _cancelled = true;
        completionHandler(NSURLSessionResponseCancel);
    }
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data {
    [_requestDelegate onSuccess:self :[_response statusCode] :[_response allHeaderFields] :data];
}

- (void)        URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
willPerformHTTPRedirection:(NSHTTPURLResponse *)response
                newRequest:(NSURLRequest *)request
         completionHandler:(void (^)(NSURLRequest *_Nullable))completionHandler {
    NSDictionary *headers = [response allHeaderFields];
    NSString *location = headers[@"location"];
    if (location) {
        _url = location;
        completionHandler([self buildRequest]);
    }
}

- (void)  URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
didCompleteWithError:(nullable NSError *)error {
    if (error != nil && !_cancelled) {
        [_requestDelegate onFailure:self :error];
    }
}

- (NSURLRequest *)buildRequest {
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:_url]];
    [request setHTTPMethod:_data == nil ? @"GET" : @"POST"];
    if (_contentType != nil) {
        [request setValue:_contentType forHTTPHeaderField:@"content-type"];
    }
    if (_data != nil) {
        [request setValue:[NSString stringWithFormat:@"%lu", (unsigned long) [_data length]] forHTTPHeaderField:@"content-length"];
        [request setHTTPBody:[_data dataUsingEncoding:NSUTF8StringEncoding]];
    }
    return request;
}

- (void)close {
    [_dataTask cancel];
}

@end
