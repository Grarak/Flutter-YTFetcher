//
// Created by Willi Ye on 25.10.18.
//

#import "MusicPlayerWrapper.h"

@implementation MusicPlayerWrapper

- (id)initWithDelegate:(id <MusicPlayerDelegate>)delegate {
    self = [super init];
    if (self) {
        _mediaPlayer = [[VLCMediaPlayer alloc] init];
        _mediaPlayer.delegate = self;
        _currentState = Idle;
        _musicPlayerDelegate = delegate;
    }
    return self;
}

- (void)mediaPlayerStateChanged:(NSNotification *)aNotification {
    switch ([self getState]) {
        case Preparing:
            if (_mediaPlayer.willPlay && [self getDuration] != 0) {
                [self setState:Idle];
                [_mediaPlayer pause];
                [_musicPlayerDelegate onPrepared];
            }
            break;
        case Playing:
            if (_mediaPlayer.isPlaying) {
                [self setState:Idle];
            }
            break;
        case Paused:
            if (_mediaPlayer.state == VLCMediaPlayerStatePaused) {
                [self setState:Idle];
                [_musicPlayerDelegate onPause];
            }
            break;
        case Seeking:
            if (_mediaPlayer.state == VLCMediaPlayerStateBuffering) {
                [self setState:Idle];
                [_musicPlayerDelegate onSeekComplete];
            }
            break;
        case Idle:
            break;
    }

    if (_mediaPlayer.state == VLCMediaPlayerStateEnded) {
        [_musicPlayerDelegate onComplete];
    }
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

- (void)setUrl:(NSString *)url {
    [self stop];
    [self setState:Preparing];
    _mediaPlayer.media = [VLCMedia mediaWithURL:[NSURL URLWithString:url]];
    [self setSession];
    [_mediaPlayer play];
}

- (void)play {
    [self setState:Playing];
    [self setSession];
    [_mediaPlayer play];
}

- (void)pause {
    [self setState:Paused];
    [_mediaPlayer pause];
}

- (void)stop {
    [_mediaPlayer stop];
}

- (BOOL)isPreparing {
    return [self getState] == Preparing;
}

- (BOOL)isPlaying {
    return _mediaPlayer.isPlaying;
}

- (int)getCurrentPosition {
    return _mediaPlayer.time.intValue;
}

- (int)getDuration {
    return [[_mediaPlayer media] length].intValue;
}

- (void)setPosition:(int)position {
    [self setState:Seeking];
    [_mediaPlayer setTime:[VLCTime timeWithInt:position]];
}

- (MusicPlayerState)getState {
    @synchronized (self) {
        return _currentState;
    }
}

- (void)setState:(MusicPlayerState)state {
    @synchronized (self) {
        _currentState = state;
    }
}

@end
