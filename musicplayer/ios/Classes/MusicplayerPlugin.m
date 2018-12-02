#import <CloudKit/CloudKit.h>
#import "MusicplayerPlugin.h"
#import "SDWebImageDownloader.h"

NSString *GetMusicplayerDirectoryOfType(NSSearchPathDirectory dir) {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(dir, NSUserDomainMask, YES);
    return paths.firstObject;
}

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
    if (![_musicPlayer isPlaying]) {
        [self resume];
        return MPRemoteCommandHandlerStatusSuccess;
    }
    return MPRemoteCommandHandlerStatusCommandFailed;
}

- (MPRemoteCommandHandlerStatus)onPauseCommand:(MPRemoteCommandEvent *)event {
    if ([_musicPlayer isPlaying]) {
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
    [_musicPlayer setPosition:(float) event.positionTime];
    [self setNowPlaying:[self getCurrentTrack]];
    return MPRemoteCommandHandlerStatusSuccess;
}

- (void)handleMethodCall:(FlutterMethodCall *)call result:(FlutterResult)result {
    NSDictionary *arguments = [call arguments];

    if ([@"notify" isEqualToString:call.method]) {
        if ([_musicPlayer isPlaying]) {
            [self onPlay];
        } else if ([_musicPlayer isPreparing]) {
            [self onPreparing];
        } else if ([self getCurrentTrack] != nil) {
            [self onPause];
        } else {
            [_channel invokeMethod:@"onDisconnect" arguments:nil];
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
        result(@([_musicPlayer getDuration]));
    } else if ([@"getPosition" isEqualToString:call.method]) {
        result(@([_musicPlayer getCurrentPosition]));
    } else if ([@"setPosition" isEqualToString:call.method]) {
        NSNumber *position = arguments[@"position"];
        [_musicPlayer setPosition:[position floatValue]];
        result(@YES);
    } else if ([@"getCurrentTrack" isEqualToString:call.method]) {
        @synchronized (self) {
            if (_currentTracks.count == 0 || _currentPosition >= _currentTracks.count) {
                result(NULL);
            } else {
                result([_currentTracks[_currentPosition] to_dictionary]);
            }
        }
    } else if ([@"stop" isEqualToString:call.method]) {
        [self setNowPlaying:nil];
        [_musicPlayer pause];
        result(@YES);
    } else if ([@"unbind" isEqualToString:call.method]) {
        result(@YES);
    } else {
        result(FlutterMethodNotImplemented);
    }
}

- (void)setNowPlaying:(YoutubeTrack *)track {
    if (!track) {
        [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:nil];
        return;
    }

    SDWebImageDownloader *downloader = [SDWebImageDownloader sharedDownloader];
    [downloader downloadImageWithURL:[
                    NSURL URLWithString:[track thumbnail]]
                             options:SDWebImageDownloaderLowPriority
                                     | SDWebImageDownloaderUseNSURLCache
                                     | SDWebImageDownloaderScaleDownLargeImages
                            progress:^(NSInteger receivedSize, NSInteger expectedSize, NSURL *_Nullable targetURL) {
                            }
                           completed:^(UIImage *_Nullable image, NSData *_Nullable data, NSError *_Nullable error, BOOL finished) {
                               if (!image) {
                                   NSBundle *bundle = [NSBundle bundleForClass:[self class]];
                                   image = [UIImage imageNamed:@"music_placeholder.png"
                                                      inBundle:bundle compatibleWithTraitCollection:nil];
                               }

                               NSArray<NSString *> *titles = [track getFormattedTitles];

                               float duration = [self->_musicPlayer getDuration];
                               float position = [self->_musicPlayer getCurrentPosition];

                               NSDictionary *info = @{
                                       MPMediaItemPropertyTitle: titles[1],
                                       MPMediaItemPropertyArtist: titles[0],
                                       MPMediaItemPropertyArtwork: [[MPMediaItemArtwork alloc] initWithImage:image],
                                       MPMediaItemPropertyPlaybackDuration: @(duration),
                                       MPNowPlayingInfoPropertyElapsedPlaybackTime: @(position),
                                       MPNowPlayingInfoPropertyPlaybackRate: @(1.0)
                               };

                               [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:info];
                           }];
}

- (void)playTracks:(NSString *)url :(NSArray<YoutubeTrack *> *)tracks :(NSUInteger)position {
    [_musicPlayer stop];

    if (!_youtubeServer) {
        if (!url) {
            return;
        }
        _youtubeServer = [[YoutubeServer alloc] initWithUrl:url];
    } else {
        [_youtubeServer close];
        if (url) {
            [_youtubeServer setUrl:url];
        }
    }

    if (!_historyServer) {
        if (!url) {
            return;
        }
        _historyServer = [[HistoryServer alloc] initWithUrl:url];
    } else if (url) {
        [_historyServer setUrl:url];
    }

    [self setTracks:tracks :position];
    [self onPreparing];

    YoutubeTrack *track = tracks[position];
    Youtube *youtube = [[Youtube alloc] init];
    youtube.apikey = track.apiKey;
    youtube.youtubeid = track.youtubeId;
    youtube.addhistory = YES;

    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *path = [NSString
            stringWithFormat:@"%@/%@.ogg", GetMusicplayerDirectoryOfType(NSDocumentDirectory), youtube.youtubeid];
    if ([fileManager fileExistsAtPath:path]) {
        [_musicPlayer setFile:path];

        History *history = [[History alloc] init];
        history.apikey = track.apiKey;
        history.id = track.youtubeId;
        [_historyServer add:history];
    } else {
        [_youtubeServer fetchSong:youtube :self];
    }
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
        [self pause];
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
    [_musicPlayer setUrl:[NSURL URLWithString:url]];
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
        if (_currentTracks.count == 0 || _currentPosition >= _currentTracks.count) {
            return nil;
        }
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
