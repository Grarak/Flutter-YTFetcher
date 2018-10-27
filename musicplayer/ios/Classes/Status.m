//
// Created by Willi Ye on 24.10.18.
//

#import "Status.h"

@implementation Status
+ (NSInteger)getStatusCode:(NSData *)data {
    NSError *error;
    id parsedJson = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    if (error != nil || ![parsedJson isMemberOfClass:[NSDictionary class]]) {
        return ServerOffline;
    }

    NSDictionary<NSString *, id> *dictionary = parsedJson;
    return (NSInteger) dictionary[@"statuscode"];
}
@end
