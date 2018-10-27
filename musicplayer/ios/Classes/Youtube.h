//
// Created by Willi Ye on 24.10.18.
//

#import <Foundation/Foundation.h>

@interface Youtube : NSObject
@property(nonatomic) NSString *apikey;

@property(nonatomic) NSString *searchquery;

@property(nonatomic) NSString *youtubeid;

@property(nonatomic) BOOL addhistory;

- (NSString *)to_string;
@end
