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
    NSLog(@"state changed %u", _mediaPlayer.state);

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
            if (!_mediaPlayer.isPlaying) {
                [self setState:Idle];
            }
            break;
        case Idle:
            break;
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
    [self setState:Preparing];
    _mediaPlayer.media = [VLCMedia mediaWithURL:[NSURL URLWithString:url]];
    [self setSession];
    [_mediaPlayer play];
}

- (void)play {
    [self setState:Playing];
    if (_mediaPlayer.state == VLCMediaPlayerStateStopped
            || _mediaPlayer.state == VLCMediaPlayerStateEnded) {
        _mediaPlayer.media = [VLCMedia mediaWithURL:_mediaPlayer.media.url];
    }
    [self setSession];
    [_mediaPlayer play];
}

- (void)pause {
    [self setState:Paused];
    [_mediaPlayer pause];
}

- (BOOL)isPreparing {
    return [self getState] == Preparing;
}

- (BOOL)isPlaying {
    return _mediaPlayer.isPlaying;
}

- (NSUInteger)getCurrentPosition {
    return (NSUInteger) _mediaPlayer.time.intValue;
}

- (NSUInteger)getDuration {
    return (NSUInteger) [[_mediaPlayer media] length].intValue;
}

- (void)setPosition:(NSUInteger)position {
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