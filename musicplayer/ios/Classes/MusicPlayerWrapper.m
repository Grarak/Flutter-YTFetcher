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
    [_musicPlayerDelegate onPrepared];
}

- (void)ogvPlayerDidPlay:(OGVPlayerView *)sender {
    [self setState:Playing];
    [_musicPlayerDelegate onPlay];
}

- (void)ogvPlayerDidPause:(OGVPlayerView *)sender {
    if ([self getState] == Paused) {
        [_musicPlayerDelegate onPause];
    }
}

- (void)ogvPlayerDidEnd:(OGVPlayerView *)sender {
    [self setState:Idle];
    [_musicPlayerDelegate onComplete];
}

- (void)ogvPlayerDidSeek:(OGVPlayerView *)sender {
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

- (float)getCurrentPosition {
    return _position == -1 ? [_playerView playbackPosition] : _position;
}

- (float)getDuration {
    return _playerView.duration;
}

- (void)setPosition:(float)position {
    if ((int) position != 0 && (int) position == (int) [self getDuration]) {
        [_musicPlayerDelegate onComplete];
    } else {
        [self setState:Seeking];
        _position = position;
        [_playerView seek:position];
    }
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
