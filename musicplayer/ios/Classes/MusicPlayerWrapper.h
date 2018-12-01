//
// Created by Willi Ye on 25.10.18.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <OGVKit/OGVKit.h>

typedef NS_ENUM(NSInteger, MusicPlayerState) {
    Preparing,
    Playing,
    Paused,
    Seeking,
    Idle
};

@protocol MusicPlayerDelegate

- (void)onPrepared;

- (void)onPlay;

- (void)onPause;

- (void)onComplete;

- (void)onSeekComplete;

@end

@interface MusicPlayerWrapper : NSObject <OGVPlayerDelegate> {
    OGVPlayerView *_playerView;
    MusicPlayerState _currentState;
    MusicPlayerState _previousState;
    float _position;
}

@property(weak, readonly, nonatomic) id <MusicPlayerDelegate> musicPlayerDelegate;

- (id)initWithDelegate:(id <MusicPlayerDelegate>)delegate;

- (void)setUrl:(NSURL *)url;

- (void)setFile:(NSString *)path;

- (void)play;

- (void)pause;

- (void)stop;

- (BOOL)isPreparing;

- (BOOL)isPlaying;

- (float)getCurrentPosition;

- (float)getDuration;

- (void)setPosition:(float)position;
@end
