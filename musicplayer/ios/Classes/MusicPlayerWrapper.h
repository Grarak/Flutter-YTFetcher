//
// Created by Willi Ye on 25.10.18.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <MobileVLCKit/MobileVLCKit.h>

typedef NS_ENUM(NSInteger, MusicPlayerState) {
    Preparing,
    Playing,
    Paused,
    Seeking,
    Idle
};

@protocol MusicPlayerDelegate

- (void)onPrepared;

- (void)onPause;

- (void)onComplete;

- (void)onSeekComplete;

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

- (void)stop;

- (BOOL)isPreparing;

- (BOOL)isPlaying;

- (int)getCurrentPosition;

- (int)getDuration;

- (void)setPosition:(int)position;
@end