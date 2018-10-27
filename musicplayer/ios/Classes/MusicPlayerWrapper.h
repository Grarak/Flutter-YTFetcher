//
// Created by Willi Ye on 25.10.18.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <MobileVLCKit/MobileVLCKit.h>

typedef NS_ENUM(NSInteger, MusicPlayerState) {
    Preparing = 0,
    Playing = 1,
    Paused = 2,
    Idle = 3
};

@protocol MusicPlayerDelegate

- (void)onPrepared;

- (void)onComplete;

@end

@interface MusicPlayerWrapper : NSObject <VLCMediaPlayerDelegate> {
    VLCMediaPlayer *_mediaPlayer;
    MusicPlayerState _currentState;
}

@property(weak, readonly, nonatomic) id <MusicPlayerDelegate> musicPlayerDelegate;

- (id)initWithDelegate:(id <MusicPlayerDelegate>)delegate;

- (void)setUrl:(NSString *)url;

- (void)play;

- (void)pause;

- (BOOL)isPreparing;

- (BOOL)isPlaying;

- (NSUInteger)getCurrentPosition;

- (NSUInteger)getDuration;

- (void)setPosition:(NSUInteger)position;
@end