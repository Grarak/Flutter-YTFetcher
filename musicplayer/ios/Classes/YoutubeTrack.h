//
// Created by Willi Ye on 19.10.18.
//

#import <Foundation/Foundation.h>

@interface YoutubeTrack : NSObject {
    NSRegularExpression *_titleExp;
}

@property(readonly, nonatomic) NSString *apiKey;

@property(readonly, nonatomic) NSString *title;

@property(readonly, nonatomic) NSString *youtubeId;

@property(readonly, nonatomic) NSString *thumbnail;

@property(readonly, nonatomic) NSString *duration;

- (id)initWithDictionary:(NSDictionary<NSString *, NSString *> *)json;

- (NSArray<NSString *> *)getFormattedTitles;

- (NSString *)to_string;

- (NSDictionary<NSString *, NSString *> *)to_dictionary;

@end
