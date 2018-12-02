//
// Created by Willi Ye on 02.12.18.
//

#import <Foundation/Foundation.h>

@interface History : NSObject
@property(nonatomic) NSString *apikey;

@property(nonatomic) NSString *id;

- (NSString *)to_string;
@end