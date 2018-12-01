//
// Created by Willi Ye on 25.10.18.
//

#import "MusicPlayerWrapper.h"
#import <math.h>

@implementation MusicPlayerWrapper

- (id)initWithDelegate:(id <MusicPlayerDelegate>)delegate {
    self = [super init];
    if (self) {
        _playerView = [[OGVPlayerView alloc] init];
        _playerView.delegate = self;
        _currentState = Idle;
        _musicPlayerDelegate = delegate;
        _position = -1;
    }
    return self;
}

- (void)ogvPlayerDidLoadMetadata:(OGVPlayerView *)sender {
    NSLog(@"ogvPlayerDidLoadMetadata");
    [_musicPlayerDelegate onPrepared];
}

- (void)ogvPlayerDidPlay:(OGVPlayerView *)sender {
    NSLog(@"ogvPlayerDidPlay");
    [self setState:Playing];
    [_musicPlayerDelegate onPlay];
}

- (void)ogvPlayerDidPause:(OGVPlayerView *)sender {
    NSLog(@"ogvPlayerDidPause");
    if ([self getState] == Paused) {
        [_musicPlayerDelegate onPause];
    }
}

- (void)ogvPlayerDidEnd:(OGVPlayerView *)sender {
    NSLog(@"ogvPlayerDidEnd");
    [self setState:Idle];
    [_musicPlayerDelegate onComplete];
}

- (void)ogvPlayerDidSeek:(OGVPlayerView *)sender {
    NSLog(@"ogvPlayerDidSeek");
    _position = -1;
    [self setState:[self getPreviousState]];
    [_musicPlayerDelegate onSeekComplete];
}

- (void)setSession {
    NSError *error;
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:&error];
    if (error != nil) {
        NSLog(@"Couldn't set category audio session playback, %@", [error localizedDescription]);
    } else {
        [[AVAudioSession sharedInstance] setActive:YES error:&error];
        if (error != nil) {
            NSLog(@"Couldn't set active audio session playback, %@", [error localizedDescription]);
        }
    }
}

- (void)setUrl:(NSURL *)url {
    [_playerView pause];
    [self setState:Preparing];
    dispatch_async(dispatch_get_main_queue(), ^{
        self->_playerView.inputStream = [OGVInputStream inputStreamWithURL:url];
    });
    [self setSession];
}

- (void)setFile:(NSString *)path {
    [self setUrl:[NSURL fileURLWithPath:path]];
}

- (void)play {
    [self setState:Playing];
    [self setSession];
    [_playerView play];
}

- (void)pause {
    [self setState:Paused];
    [_playerView pause];
}

- (void)stop {
    [_playerView pause];
}

- (BOOL)isPreparing {
    return [self getState] == Preparing;
}

- (BOOL)isPlaying {
    return [self getState] == Playing;
}

- (int)getCurrentPosition {
    return _position == -1 ? (int) ([_playerView playbackPosition] * 1000) : _position;
}

- (int)getDuration {
    return (int) (_playerView.duration * 1000);
}

- (void)setPosition:(int)position {
    [self setState:Seeking];
    _position = position;
    [_playerView seek:position / 1000];
}

- (MusicPlayerState)getState {
    @synchronized (self) {
        return _currentState;
    }
}

- (MusicPlayerState)getPreviousState {
    @synchronized (self) {
        return _previousState;
    }
}

- (void)setState:(MusicPlayerState)state {
    @synchronized (self) {
        _previousState = _currentState;
        _currentState = state;
    }
}

@end
