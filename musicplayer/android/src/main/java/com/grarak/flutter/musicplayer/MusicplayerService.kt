package com.grarak.flutter.musicplayer

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.os.Build
import android.os.Bundle
import android.support.v4.media.MediaBrowserCompat
import android.support.v4.media.MediaBrowserServiceCompat
import android.support.v4.media.session.MediaSessionCompat
import android.support.v4.media.session.PlaybackStateCompat
import com.google.android.exoplayer2.C
import com.google.android.exoplayer2.ExoPlaybackException
import com.google.android.exoplayer2.audio.AudioAttributes
import com.grarak.flutter.musicplayer.network.History
import com.grarak.flutter.musicplayer.network.HistoryServer
import com.grarak.flutter.musicplayer.network.Youtube
import com.grarak.flutter.musicplayer.network.YoutubeServer
import io.flutter.util.PathUtils
import java.io.File


class MusicplayerService : MediaBrowserServiceCompat(), ExoPlayerWrapper.OnPlayerListener, AudioManager.OnAudioFocusChangeListener {

    private val mYoutubeServer = YoutubeServer()
    private val mHistoryServer = HistoryServer()

    private lateinit var mExoPlayer: ExoPlayerWrapper
    private lateinit var mNotification: MusicplayerNotification
    private lateinit var mSession: MediaSessionCompat
    private val mSessionCallback = MediaSessionCallback()

    private val mTrackLock = Any()

    private var mPreparing = false
    private var mTrackPosition: Int = 0
    private val mTracks = ArrayList<MusicTrack>()
    private var mState: Int = 0
        set(value) {
            synchronized(mTrackLock) {
                field = value

                var actions = PlaybackStateCompat.ACTION_STOP
                if (mTracks.size > 1) {
                    actions = actions or
                            PlaybackStateCompat.ACTION_SKIP_TO_PREVIOUS or
                            PlaybackStateCompat.ACTION_SKIP_TO_NEXT
                }
                when (value) {
                    PlaybackStateCompat.STATE_PLAYING -> {
                        actions = actions or
                                PlaybackStateCompat.ACTION_PAUSE or
                                PlaybackStateCompat.ACTION_SEEK_TO
                    }
                    PlaybackStateCompat.STATE_PAUSED -> {
                        actions = actions or
                                PlaybackStateCompat.ACTION_PLAY or
                                PlaybackStateCompat.ACTION_SEEK_TO
                    }
                }

                val bundle = Bundle()
                bundle.putParcelableArrayList("tracks", mTracks)
                bundle.putInt("position", mTrackPosition)
                bundle.putFloat("duration", mExoPlayer.duration)

                val state = PlaybackStateCompat.Builder()
                        .setActions(actions)
                        .setExtras(bundle)
                        .setState(value, (mExoPlayer.currentPosition * 1000).toLong(), 1f)
                        .build()
                mSession.setPlaybackState(state)
                mNotification.showNotification(mTracks[mTrackPosition], state, mSession)
            }
        }

    private lateinit var mAudioManager: AudioManager
    private lateinit var mAudioFocusRequest: AudioFocusRequest

    private val mFocusLock = Any()
    private var mPlaybackDelayed: Boolean = false
    private var mResumeOnFocusGain: Boolean = false

    override fun onCreate() {
        super.onCreate()

        mExoPlayer = ExoPlayerWrapper(this)
        mExoPlayer.onPlayerListener = this
        mExoPlayer.setAudioAttributes(AudioAttributes.Builder()
                .setContentType(C.CONTENT_TYPE_MUSIC)
                .setUsage(C.USAGE_MEDIA).build())

        mNotification = MusicplayerNotification(this)

        mAudioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            mAudioFocusRequest = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN)
                    .setAcceptsDelayedFocusGain(true)
                    .setWillPauseWhenDucked(true)
                    .setOnAudioFocusChangeListener(this)
                    .build()
        }

        mSession = MediaSessionCompat(this, "Musicplayer")
        mSession.setCallback(mSessionCallback)
        mSession.setFlags(MediaSessionCompat.FLAG_HANDLES_MEDIA_BUTTONS
                or MediaSessionCompat.FLAG_HANDLES_QUEUE_COMMANDS
                or MediaSessionCompat.FLAG_HANDLES_TRANSPORT_CONTROLS)
        sessionToken = mSession.sessionToken

        registerReceiver(mReceiver, IntentFilter(AudioManager.ACTION_AUDIO_BECOMING_NOISY))
    }

    override fun onDestroy() {
        super.onDestroy()

        Log.i("Cleaning up")

        unregisterReceiver(mReceiver)

        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            mAudioManager.abandonAudioFocus(this)
        }

        mYoutubeServer.close()
        mHistoryServer.close()

        mExoPlayer.release()
        mSession.release()

        mNotification.destroy()
    }

    @Synchronized
    fun playMusic(url: String, tracks: ArrayList<MusicTrack>, position: Int) {
        mExoPlayer.stop()
        mYoutubeServer.close()

        synchronized(mTrackLock) {
            mPreparing = true
            mTrackPosition = position
            if (tracks !== mTracks) {
                mTracks.clear()
                mTracks.addAll(tracks)

                val queue = ArrayList<MediaSessionCompat.QueueItem>()
                for (item in tracksToMediaItems()) {
                    queue.add(MediaSessionCompat.QueueItem(item.description, item.description.hashCode().toLong()))
                }
                mSession.setQueue(queue)
            }
        }

        if (!mSession.isActive) {
            mSession.isActive = true
        }

        mState = PlaybackStateCompat.STATE_CONNECTING

        val track = tracks[position]

        val youtube = Youtube()
        youtube.apikey = track.apiKey
        youtube.id = track.id
        youtube.addhistory = true

        mYoutubeServer.url = url
        mHistoryServer.url = url

        val file = File(PathUtils.getDataDirectory(this), youtube.id + ".ogg")
        if (file.exists()) {
            mExoPlayer.setFile(file)

            val history = History()
            history.apikey = track.apiKey
            history.id = track.id
            mHistoryServer.add(history)
            return
        }

        mYoutubeServer.fetchSong(youtube, object : YoutubeServer.YoutubeSongIdCallback {
            override fun onSuccess(url: String) {
                mExoPlayer.setUrl(url)
            }

            override fun onFailure(code: Int) {
                mState = PlaybackStateCompat.STATE_ERROR
                next()
            }
        })
    }

    private fun play() {
        synchronized(mTrackLock) {
            if (!mExoPlayer.isPlaying) {
                mExoPlayer.play()
                mState = PlaybackStateCompat.STATE_PLAYING
            }
        }
    }

    private fun resume() {
        requestAudioFocus()
    }

    private fun pause() {
        synchronized(mTrackLock) {
            mExoPlayer.pause()
            mState = PlaybackStateCompat.STATE_PAUSED
            synchronized(mFocusLock) {
                mResumeOnFocusGain = false
            }
        }
    }

    private fun previous() {
        synchronized(mTrackLock) {
            if (getTrack(mTrackPosition - 1) != null) {
                playMusic(mYoutubeServer.url, mTracks, mTrackPosition - 1)
            }
        }
    }

    private fun next() {
        synchronized(mTrackLock) {
            if (getTrack(mTrackPosition + 1) != null) {
                playMusic(mYoutubeServer.url, mTracks, mTrackPosition + 1)
            }
        }
    }

    private fun getTrack(position: Int): MusicTrack? {
        synchronized(mTrackLock) {
            if (position >= 0 && position < mTracks.size) {
                return mTracks[position]
            }
            return null
        }
    }

    override fun onPrepared(exoPlayer: ExoPlayerWrapper) {
        synchronized(mTrackLock) {
            mPreparing = false
            requestAudioFocus()
        }
    }

    override fun onSeekComplete(exoPlayer: ExoPlayerWrapper) {
        mState = mState
    }

    override fun onCompletion(exoPlayer: ExoPlayerWrapper) {
        synchronized(mTrackLock) {
            pause()
            exoPlayer.seekTo(0f)
            next()
        }
    }

    override fun onError(exoPlayer: ExoPlayerWrapper, error: ExoPlaybackException) {
        mState = PlaybackStateCompat.STATE_ERROR
    }

    override fun onAudioFocusChange(focusChange: Int) {
        when (focusChange) {
            AudioManager.AUDIOFOCUS_GAIN -> if (mPlaybackDelayed || mResumeOnFocusGain) {
                synchronized(mFocusLock) {
                    mPlaybackDelayed = false
                    mResumeOnFocusGain = false
                }
                mExoPlayer.setVolume(1.0f)
                play()
            }
            AudioManager.AUDIOFOCUS_LOSS -> {
                synchronized(mFocusLock) {
                    mResumeOnFocusGain = false
                    mPlaybackDelayed = false
                }
                pause()
            }
            AudioManager.AUDIOFOCUS_LOSS_TRANSIENT -> {
                synchronized(mFocusLock) {
                    mResumeOnFocusGain = mExoPlayer.isPlaying
                    mPlaybackDelayed = false
                }
                pause()
            }
            AudioManager.AUDIOFOCUS_LOSS_TRANSIENT_CAN_DUCK -> {
                mExoPlayer.setVolume(0.2f)
            }
        }
    }

    private fun requestAudioFocus() {
        val ret: Int = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            mAudioManager.requestAudioFocus(mAudioFocusRequest)
        } else {
            mAudioManager.requestAudioFocus(this,
                    AudioManager.STREAM_MUSIC, AudioManager.AUDIOFOCUS_GAIN)
        }
        synchronized(mFocusLock) {
            when (ret) {
                AudioManager.AUDIOFOCUS_REQUEST_FAILED -> mPlaybackDelayed = false
                AudioManager.AUDIOFOCUS_REQUEST_GRANTED -> {
                    mPlaybackDelayed = false
                    play()
                }
                AudioManager.AUDIOFOCUS_REQUEST_DELAYED -> mPlaybackDelayed = true
            }
        }
    }

    private val mReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (AudioManager.ACTION_AUDIO_BECOMING_NOISY == intent?.action) {
                pause()
            }
        }
    }

    override fun onTaskRemoved(rootIntent: Intent?) {
        super.onTaskRemoved(rootIntent)
        stopSelf()
    }

    private inner class MediaSessionCallback : MediaSessionCompat.Callback() {
        override fun onPlay() {
            super.onPlay()
            resume()
        }

        override fun onPause() {
            super.onPause()
            pause()
        }

        override fun onStop() {
            super.onStop()
            mState = PlaybackStateCompat.STATE_STOPPED
            mSession.isActive = false
        }

        override fun onCustomAction(action: String?, extras: Bundle?) {
            super.onCustomAction(action, extras)

            action?.run {
                when (this) {
                    PLAY_TRACKS -> {
                        extras!!.run {
                            val url = getString("url")
                            val tracks = getParcelableArrayList<MusicTrack>("tracks")
                            val position = getInt("position")

                            playMusic(url!!, tracks!!, position)
                        }
                    }
                }
            }
        }

        override fun onSeekTo(pos: Long) {
            super.onSeekTo(pos)
            mExoPlayer.seekTo(pos.toFloat() / 1000)
            mState = mState
        }

        override fun onSkipToPrevious() {
            super.onSkipToPrevious()
            previous()
        }

        override fun onSkipToNext() {
            super.onSkipToNext()
            next()
        }
    }

    private fun tracksToMediaItems(): ArrayList<MediaBrowserCompat.MediaItem> {
        synchronized(mTrackLock) {
            val items = ArrayList<MediaBrowserCompat.MediaItem>()
            for (track in mTracks) {
                items.add(MediaBrowserCompat.MediaItem(track.toMetadataBuilder().build().description,
                        MediaBrowserCompat.MediaItem.FLAG_PLAYABLE))
            }
            return items
        }
    }

    override fun onLoadChildren(parentId: String, result: Result<MutableList<MediaBrowserCompat.MediaItem>>) {
        result.sendResult(tracksToMediaItems())
    }

    override fun onGetRoot(clientPackageName: String, clientUid: Int, rootHints: Bundle?): BrowserRoot? {
        return BrowserRoot("root", null)
    }

    companion object {
        const val PLAY_TRACKS = "play_tracks"
    }
}
