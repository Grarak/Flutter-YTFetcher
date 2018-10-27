//
// Created by Willi Ye on 24.10.18.
//

#import <Foundation/Foundation.h>

#define ServerOffline -1
#define NoError 0
#define Invalid 1
#define NameShort 2
#define PasswordShort 3
#define PasswordInvalid 4
#define NameInvalid 5
#define AddUserFailed 6
#define UserAlreadyExists 7
#define InvalidPassword 8
#define PasswordLong 9
#define NameLong 10
#define YoutubeFetchFailure 11
#define YoutubeSearchFailure 12
#define YoutubeGetFailure 13
#define YoutubeGetInfoFailure 14
#define YoutubeGetChartsFailure 15
#define PlaylistIdAlreadyExists 16
#define AddHistoryFailed 17

@interface Status : NSObject
+ (NSInteger)getStatusCode:(NSData *)data;
@end
