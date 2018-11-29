//
// Created by Willi Ye on 19.10.18.
//

#import "YoutubeTrack.h"

@implementation YoutubeTrack
- (instancetype)init {
    self = [super init];
    if (self) {
        NSError *error;
        NSRegularExpression *expression = [NSRegularExpression
                regularExpressionWithPattern:@"(.+)[:|-](.+)" options:0 error:&error];
        if (error == nil) {
            _titleExp = expression;
        } else {
            NSLog(@"couldn't creat regex, %@", [error localizedDescription]);
        }
    }
    return self;
}

- (id)initWithDictionary:(NSDictionary<NSString *, NSString *> *)json {
    self = [self init];
    if (self) {
        _apiKey = json[@"apiKey"];
        _title = json[@"title"];
        _youtubeId = json[@"id"];
        _thumbnail = json[@"thumbnail"];
        _duration = json[@"duration"];
    }
    return self;
}

- (NSArray<NSString *> *)getFormattedTitles {
    NSRange range = NSMakeRange(0, [_title length]);
    NSArray<NSTextCheckingResult *> *matches = [_titleExp matchesInString:_title options:0 range:range];
    if ([matches count] > 0) {
        NSString *title1 = [[_title substringWithRange:[matches[0] rangeAtIndex:1]]
                stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        NSString *title2 = [[_title substringWithRange:[matches[0] rangeAtIndex:2]]
                stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        return [@[title1, title2] mutableCopy];
    }
    return [@[_youtubeId, _title] mutableCopy];
}

- (NSString *)to_string {
    NSDictionary *dictionary = [self to_dictionary];

    NSError *error;
    NSData *data = [NSJSONSerialization dataWithJSONObject:dictionary options:0 error:&error];
    if (error != nil) {
        return nil;
    }
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

- (NSDictionary<NSString *, NSString *> *)to_dictionary {
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    dictionary[@"apiKey"] = _apiKey;
    dictionary[@"title"] = _title;
    dictionary[@"id"] = _youtubeId;
    dictionary[@"thumbnail"] = _thumbnail;
    dictionary[@"duration"] = _duration;
    return dictionary;
}

@end
