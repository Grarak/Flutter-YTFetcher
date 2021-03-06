#import <Flutter/Flutter.h>
#import <MediaPlayer/MediaPlayer.h>

#import "HistoryServer.h"
#import "MusicPlayerWrapper.h"
#import "YoutubeTrack.h"
#import "YoutubeServer.h"

@interface MusicplayerPlugin : NSObject <FlutterPlugin, MusicPlayerDelegate, YoutubeServerDelegate> {
    FlutterMethodChannel *_channel;
    YoutubeServer *_youtubeServer;
    HistoryServer *_historyServer;

    NSArray<YoutubeTrack *> *_currentTracks;
    NSUInteger _currentPosition;

    MPRemoteCommandCenter *_commandCenter;
}
@property(readonly, nonatomic) MusicPlayerWrapper *musicPlayer;

- (id)initWithChannel:(FlutterMethodChannel *)channel;
@end
