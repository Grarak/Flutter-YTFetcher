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
                regularExpressionWithPattern:@"(.+)[:| -] (.+)" options:0 error:&error];
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
        NSString *title1 = [_title substringWithRange:[matches[0] rangeAtIndex:1]];
        NSString *title2 = [_title substringWithRange:[matches[0] rangeAtIndex:2]];
        return [@[title1, title2] mutableCopy];
    }

    NSString *formattedTitle = _title;
    NSString *contentText = _youtubeId;
    if ([_title length] > 20) {
        NSString *tmp = [_title substringFromIndex:20];
        NSRange whitespaceRange = [tmp rangeOfString:@" "];
        if (whitespaceRange.location != NSNotFound) {
            NSUInteger firstWhitespace = 20 + whitespaceRange.location;
            contentText = [_title substringFromIndex:firstWhitespace + 1];
            _title = [_title substringToIndex:firstWhitespace];
        }
    }
    return [@[formattedTitle, contentText] mutableCopy];
}

- (NSString *)to_string {
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    dictionary[@"apiKey"] = _apiKey;
    dictionary[@"title"] = _title;
    dictionary[@"id"] = _youtubeId;
    dictionary[@"thumbnail"] = _thumbnail;
    dictionary[@"duration"] = _duration;

    NSError *error;
    NSData *data = [NSJSONSerialization dataWithJSONObject:dictionary options:0 error:&error];
    if (error != nil) {
        return nil;
    }
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}
@end
