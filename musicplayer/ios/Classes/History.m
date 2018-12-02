//
// Created by Willi Ye on 02.12.18.
//

#import "History.h"

@implementation History
- (NSString *)to_string {
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    dictionary[@"apikey"] = _apikey;
    dictionary[@"id"] = _id;

    NSError *error;
    NSData *data = [NSJSONSerialization dataWithJSONObject:dictionary options:0 error:&error];
    if (error != nil) {
        return nil;
    }
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}
@end