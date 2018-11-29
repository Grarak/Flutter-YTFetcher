#import <CloudKit/CloudKit.h>
#import "MusicplayerPlugin.h"
#import "SDWebImageDownloader.h"

@implementation MusicplayerPlugin
+ (void)registerWithRegistrar:(NSObject <FlutterPluginRegistrar> *)registrar {
    FlutterMethodChannel *channel = [FlutterMethodChannel
            methodChannelWithName:@"musicplayer"
                  binaryMessenger:[registrar messenger]];
    MusicplayerPlugin *instance = [[MusicplayerPlugin alloc] initWithChannel:channel];
    [registrar addMethodCallDelegate:instance channel:channel];
}

- (id)initWithChannel:(FlutterMethodChannel *)channel {
    self = [super init];
    if (self) {
        _channel = channel;
        _musicPlayer = [[MusicPlayerWrapper alloc] initWithDelegate:self];
        _commandCenter = [MPRemoteCommandCenter sharedCommandCenter];
        [[_commandCenter playCommand] addTarget:self action:@selector(onPlayCommand:)];
        [[_commandCenter pauseCommand] addTarget:self action:@selector(onPauseCommand:)];
        [[_commandCenter previousTrackCommand] addTarget:self action:@selector(onPreviousCommand:)];
        [[_commandCenter nextTrackCommand] addTarget:self action:@selector(onNextCommand:)];
        if (@available(iOS 9.1, *)) {
            [[_commandCenter changePlaybackPositionCommand] addTarget:self action:@selector(onPlaybackPositionCommand:)];
        }
    }
    return self;
}

- (MPRemoteCommandHandlerStatus)onPlayCommand:(MPRemoteCommandEvent *)event {
    NSArray<YoutubeTrack *> *tracks = [self getTracks];
    NSUInteger currentPosition = [self getPosition];
    if (![_musicPlayer isPlaying]
            && tracks != nil && [tracks count] > 0
            && currentPosition >= 0
            && currentPosition < [tracks count]) {
        [self resume];
        return MPRemoteCommandHandlerStatusSuccess;
    }
    return MPRemoteCommandHandlerStatusCommandFailed;
}

- (MPRemoteCommandHandlerStatus)onPauseCommand:(MPRemoteCommandEvent *)event {
    NSArray<YoutubeTrack *> *tracks = [self getTracks];
    NSUInteger currentPosition = [self getPosition];
    if ([_musicPlayer isPlaying]
            && tracks != nil && [tracks count] > 0
            && currentPosition >= 0
            && currentPosition < [tracks count]) {
        [self pause];
        return MPRemoteCommandHandlerStatusSuccess;
    }
    return MPRemoteCommandHandlerStatusCommandFailed;
}

- (MPRemoteCommandHandlerStatus)onPreviousCommand:(MPRemoteCommandEvent *)event {
    if ([self hasPrevious]) {
        [self moveToPrevious];
        return MPRemoteCommandHandlerStatusSuccess;
    }
    return MPRemoteCommandHandlerStatusCommandFailed;
}

- (MPRemoteCommandHandlerStatus)onNextCommand:(MPRemoteCommandEvent *)event {
    if ([self hasNext]) {
        [self moveToNext];
        return MPRemoteCommandHandlerStatusSuccess;
    }
    return MPRemoteCommandHandlerStatusCommandFailed;
}

- (MPRemoteCommandHandlerStatus)onPlaybackPositionCommand:(MPChangePlaybackPositionCommandEvent *)event {
    [_musicPlayer setPosition:(int) (event.positionTime * 1000)];
    return MPRemoteCommandHandlerStatusSuccess;
}

- (void)handleMethodCall:(FlutterMethodCall *)call result:(FlutterResult)result {
    NSDictionary *arguments = [call arguments];

    if ([@"notify" isEqualToString:call.method]) {
        if ([_musicPlayer isPlaying]) {
            [self onPlay];
        } else if ([_musicPlayer isPreparing]) {
            [self onPreparing];
        } else {
            NSArray<YoutubeTrack *> *tracks = [self getTracks];
            NSUInteger currentPosition = [self getPosition];
            if (tracks != nil && [tracks count] > 0
                    && currentPosition >= 0
                    && currentPosition < [tracks count]) {
                [self onPause];
            } else {
                [_channel invokeMethod:@"onDisconnect" arguments:nil];
            }
        }
        result(@YES);
    } else if ([@"playTracks" isEqualToString:call.method]) {
        NSString *url = arguments[@"url"];
        NSArray<NSDictionary<NSString *, NSString *> *> *tracks = arguments[@"tracks"];
        NSNumber *position = arguments[@"position"];

        NSMutableArray<YoutubeTrack *> *musicTracks = [NSMutableArray arrayWithCapacity:tracks.count];
        for (NSUInteger i = 0; i < tracks.count; i++) {
            YoutubeTrack *track = [[YoutubeTrack alloc] initWithDictionary:tracks[i]];
            musicTracks[i] = track;
        }

        [self playTracks:url :musicTracks :[position unsignedIntegerValue]];

        result(@YES);
    } else if ([@"resume" isEqualToString:call.method]) {
        [self resume];
        result(@YES);
    } else if ([@"pause" isEqualToString:call.method]) {
        [self pause];
        result(@YES);
    } else if ([@"getDuration" isEqualToString:call.method]) {
        result(@([_musicPlayer getDuration] / 1000));
    } else if ([@"getPosition" isEqualToString:call.method]) {
        result(@([_musicPlayer getCurrentPosition] / 1000));
    } else if ([@"setPosition" isEqualToString:call.method]) {
        NSNumber *position = arguments[@"position"];
        [_musicPlayer setPosition:(int) [position integerValue] * 1000];
        result(@YES);
    } else if ([@"getCurrentTrack" isEqualToString:call.method]) {
        @synchronized (self) {
            if (_currentTracks.count == 0 || _currentPosition >= _currentTracks.count) {
                result(NULL);
            } else {
                result([_currentTracks[_currentPosition] to_dictionary]);
            }
        }
    } else if ([@"unbind" isEqualToString:call.method]) {
        result(@YES);
    } else {
        result(FlutterMethodNotImplemented);
    }
}

- (void)setNowPlaying:(YoutubeTrack *)track {
    SDWebImageDownloader *downloader = [SDWebImageDownloader sharedDownloader];
    [downloader downloadImageWithURL:[
                    NSURL URLWithString:[track thumbnail]]
                             options:SDWebImageDownloaderContinueInBackground
                            progress:^(NSInteger receivedSize, NSInteger expectedSize, NSURL *_Nullable targetURL) {
                            }
                           completed:^(UIImage *_Nullable image, NSData *_Nullable data, NSError *_Nullable error, BOOL finished) {
                               if (!image) {
                                   image = [UIImage imageNamed:@"music_placeholder"];
                               }

                               NSArray<NSString *> *titles = [track getFormattedTitles];

                               NSDictionary *info = @{
                                       MPMediaItemPropertyTitle: titles[1],
                                       MPMediaItemPropertyArtist: titles[0],
                                       MPMediaItemPropertyArtwork: [[MPMediaItemArtwork alloc] initWithImage:image],
                                       MPMediaItemPropertyPlaybackDuration: @([self.musicPlayer getDuration] / 1000),
                                       MPNowPlayingInfoPropertyElapsedPlaybackTime: @([self.musicPlayer getCurrentPosition] / 1000),
                                       MPNowPlayingInfoPropertyPlaybackRate: @(1.0)
                               };

                               [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:info];
                           }];
}

- (void)playTracks:(NSString *)url :(NSArray<YoutubeTrack *> *)tracks :(NSUInteger)position {
    if ([_musicPlayer isPlaying]) {
        [_musicPlayer stop];
    }

    if (_server == nil) {
        if (url == nil) {
            return;
        }
        _server = [[YoutubeServer alloc] initWithUrl:url];
    } else {
        [_server close];
        if (url != nil) {
            [_server setUrl:url];
        }
    }

    [self setTracks:tracks :position];
    [self onPreparing];

    YoutubeTrack *track = tracks[position];
    Youtube *youtube = [[Youtube alloc] init];
    youtube.apikey = track.apiKey;
    youtube.youtubeid = track.youtubeId;
    [_server fetchSong:youtube :self];
}

- (void)onPreparing {
    [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:nil];

    NSMutableDictionary *arguments = [NSMutableDictionary dictionary];
    arguments[@"tracks"] = [self getArgumentTracks];
    arguments[@"position"] = @([self getPosition]);

    [_channel invokeMethod:@"onPreparing" arguments:arguments];
}

- (void)onPlay {
    [self setNowPlaying:[self getCurrentTrack]];

    NSMutableDictionary *arguments = [NSMutableDictionary dictionary];
    arguments[@"tracks"] = [self getArgumentTracks];
    arguments[@"position"] = @([self getPosition]);

    [_channel invokeMethod:@"onPlay" arguments:arguments];
}

- (void)onPause {
    [self setNowPlaying:[self getCurrentTrack]];

    NSMutableDictionary *arguments = [NSMutableDictionary dictionary];
    arguments[@"tracks"] = [self getArgumentTracks];
    arguments[@"position"] = @([self getPosition]);

    [_channel invokeMethod:@"onPause" arguments:arguments];
}

- (void)onPrepared {
    [self resume];
}

- (void)onComplete {
    if ([self hasNext]) {
        [self moveToNext];
    } else {
        [_musicPlayer setPosition:0];
        [self setNowPlaying:[self getCurrentTrack]];
    }
}

- (void)onSeekComplete {
    [self setNowPlaying:[self getCurrentTrack]];
}

- (void)resume {
    [_musicPlayer play];
    [self onPlay];
}

- (void)pause {
    [_musicPlayer pause];
}

- (void)onSuccess:(NSString *)url {
    [_musicPlayer setUrl:url];
}

- (void)onFailure:(NSInteger)code {
    NSMutableDictionary *arguments = [NSMutableDictionary dictionary];
    arguments[@"code"] = @(code);
    arguments[@"tracks"] = [self getArgumentTracks];
    arguments[@"position"] = @([self getPosition]);

    [_channel invokeMethod:@"onFailure" arguments:arguments];
}

- (NSArray<NSString *> *)getArgumentTracks {
    NSArray<YoutubeTrack *> *tracks = [self getTracks];
    NSMutableArray<NSString *> *parsedTracks = [NSMutableArray arrayWithCapacity:[tracks count]];
    for (NSUInteger i = 0; i < [tracks count]; i++) {
        parsedTracks[i] = [tracks[i] to_string];
    }
    return parsedTracks;
}

- (BOOL)hasPrevious {
    @synchronized (self) {
        return _currentTracks != nil && _currentPosition - 1 >= 0 && _currentPosition - 1 < [_currentTracks count];
    }
}

- (BOOL)hasNext {
    @synchronized (self) {
        return _currentTracks != nil && _currentPosition + 1 > 0 && _currentPosition + 1 < [_currentTracks count];
    }
}

- (void)moveToPrevious {
    @synchronized (self) {
        if ([self hasPrevious]) {
            [self playTracks:nil :_currentTracks :--_currentPosition];
        }
    }
}

- (void)moveToNext {
    @synchronized (self) {
        if ([self hasNext]) {
            [self playTracks:nil :_currentTracks :++_currentPosition];
        }
    }
}

- (YoutubeTrack *)getCurrentTrack {
    @synchronized (self) {
        return _currentTracks[_currentPosition];
    }
}

- (NSUInteger)getPosition {
    @synchronized (self) {
        return _currentPosition;
    }
}

- (void)setTracks:(NSArray<YoutubeTrack *> *)tracks :(NSUInteger)position {
    @synchronized (self) {
        _currentTracks = tracks;
        _currentPosition = position;
    }
}

- (NSArray<YoutubeTrack *> *)getTracks {
    @synchronized (self) {
        return _currentTracks;
    }
}

@end
