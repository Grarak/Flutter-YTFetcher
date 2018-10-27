//
// Created by Willi Ye on 24.10.18.
//

#import "Youtube.h"

@implementation Youtube
- (NSString *)to_string {
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    dictionary[@"apikey"] = _apikey;
    dictionary[@"searchquery"] = _searchquery;
    dictionary[@"id"] = _youtubeid;
    dictionary[@"addhistory"] = @(_addhistory);

    NSError *error;
    NSData *data = [NSJSONSerialization dataWithJSONObject:dictionary options:0 error:&error];
    if (error != nil) {
        return nil;
    }
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}
@end
