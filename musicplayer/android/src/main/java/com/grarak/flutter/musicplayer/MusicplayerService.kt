package com.grarak.flutter.musicplayer

import android.app.Service
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.os.Binder
import android.os.Build
import android.os.IBinder
import com.google.android.exoplayer2.C
import com.google.android.exoplayer2.ExoPlaybackException
import com.google.android.exoplayer2.audio.AudioAttributes
import com.grarak.flutter.musicplayer.network.Status
import com.grarak.flutter.musicplayer.network.Youtube
import com.grarak.flutter.musicplayer.network.YoutubeServer
import io.flutter.util.PathUtils
import java.io.File
import java.nio.file.Path
import java.util.*

class MusicplayerService : Service(), AudioManager.OnAudioFocusChangeListener, ExoPlayerWrapper.OnPlayerListener {
    companion object {
        private val NAME = MusicplayerService::class.java.name
        val ACTION_MUSIC_PLAYER_STOP = "$NAME.ACTION.MUSIC_PLAYER_STOP"
        val ACTION_MUSIC_PLAY_PAUSE = "$NAME.ACTION.MUSIC_PLAY_PAUSE"
        val ACTION_MUSIC_PREVIOUS = "$NAME.ACTION.MUSIC_PREVIOUS"
        val ACTION_MUSIC_NEXT = "$NAME.ACTION.MUSIC_NEXT"
    }

    private val binder = MusicPlayerBinder()

    private val youtubeServer = YoutubeServer()
    private lateinit var exoPlayer: ExoPlayerWrapper
    private lateinit var notification: MusicplayerNotification
    private lateinit var audioManager: AudioManager
    var listener: MusicPlayerListener? = null

    private lateinit var audioFocusRequest: AudioFocusRequest

    private val focusLock = Any()
    private var playbackDelayed: Boolean = false
    private var resumeOnFocusGain: Boolean = false

    private val trackLock = Any()
    private val tracks = ArrayList<MusicTrack>()
    private var preparing: Boolean = false
    var trackPosition = -1
        private set
    private var lastMusicPosition: Float = .0f

    private val receiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            if (intent.action == ACTION_MUSIC_PLAYER_STOP) {
                stopForeground(true)
                if (listener != null) {
                    listener!!.onDisconnect()
                } else {
                    stopSelf()
                }
            } else if (intent.action == ACTION_MUSIC_PLAY_PAUSE) {
                if (isPlaying) {
                    pauseMusic()
                } else {
                    requestAudioFocus()
                }
            } else if (intent.action == ACTION_MUSIC_PREVIOUS) {
                synchronized(trackLock) {
                    if (trackPosition - 1 >= 0 && trackPosition - 1 < tracks.size) {
                        playMusic(youtubeServer.url, tracks, trackPosition - 1)
                    }
                }
            } else if (intent.action == ACTION_MUSIC_NEXT) {
                synchronized(trackLock) {
                    if (trackPosition != -1 && trackPosition + 1 < tracks.size) {
                        playMusic(youtubeServer.url, tracks, trackPosition + 1)
                    }
                }
            } else if (intent.action == AudioManager.ACTION_AUDIO_BECOMING_NOISY) {
                pauseMusic()
            }

            Log.i(intent.action)
        }
    }

    val isPlaying: Boolean
        get() = synchronized(trackLock) {
            return exoPlayer.isPlaying && trackPosition >= 0
        }

    val currentPosition: Float
        get() = exoPlayer.currentPosition

    val duration: Float
        get() = exoPlayer.duration

    val isPreparing: Boolean
        get() = synchronized(trackLock) {
            return preparing && trackPosition >= 0
        }

    inner class MusicPlayerBinder : Binder() {
        val service: MusicplayerService
            get() = this@MusicplayerService
    }

    override fun onCreate() {
        super.onCreate()

        exoPlayer = ExoPlayerWrapper(this)
        exoPlayer.onPlayerListener = this
        val audioAttributes = AudioAttributes.Builder()
                .setContentType(C.CONTENT_TYPE_MUSIC)
                .setUsage(C.USAGE_MEDIA).build()
        exoPlayer.setAudioAttributes(audioAttributes)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            audioFocusRequest = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN)
                    .setAcceptsDelayedFocusGain(true)
                    .setWillPauseWhenDucked(true)
                    .setOnAudioFocusChangeListener(this)
                    .build()
        }

        notification = MusicplayerNotification(this)

        audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager

        val filter = IntentFilter()
        filter.addAction(ACTION_MUSIC_PLAYER_STOP)
        filter.addAction(ACTION_MUSIC_PLAY_PAUSE)
        filter.addAction(ACTION_MUSIC_PREVIOUS)
        filter.addAction(ACTION_MUSIC_NEXT)
        filter.addAction(AudioManager.ACTION_AUDIO_BECOMING_NOISY)
        filter.addAction(Intent.ACTION_MEDIA_BUTTON)
        registerReceiver(receiver, filter)
    }

    @Synchronized
    fun playMusic(url: String, tracks: List<MusicTrack>, position: Int) {
        pauseMusic()
        youtubeServer.close()

        synchronized(trackLock) {
            preparing = true
            trackPosition = position
            lastMusicPosition = .0f
            if (this.tracks !== tracks) {
                this.tracks.clear()
                this.tracks.addAll(tracks)
            }
        }

        listener?.onPreparing(tracks, position)

        val track = tracks[position]
        notification.showProgress(track)

        val youtube = Youtube()
        youtube.apikey = track.apiKey
        youtube.id = track.id
        youtube.addhistory = true
        youtubeServer.url = url

        val file = File(PathUtils.getDataDirectory(this), youtube.id + ".ogg")
        if (file.exists()) {
            exoPlayer.setFile(file)
            return
        }

        youtubeServer.fetchSong(youtube, object : YoutubeServer.YoutubeSongIdCallback {
            override fun onSuccess(url: String) {
                exoPlayer.setUrl(url)
            }

            override fun onFailure(code: Int) {
                listener?.onFailure(code, tracks, position)
                synchronized(trackLock) {
                    if (moveOn()) {
                        playMusic(youtubeServer.url, tracks, trackPosition + 1)
                    } else {
                        trackPosition = -1
                    }
                }
                notification.showFailure(track)
            }
        })
    }

    fun resumeMusic() {
        requestAudioFocus()
    }

    private fun playMusic() {
        synchronized(trackLock) {
            if (trackPosition < 0) {
                return
            }
            seekTo(lastMusicPosition)
            exoPlayer.play()
            notification.showPlay(tracks[trackPosition])
            listener?.onPlay(tracks, trackPosition)
        }
    }

    fun pauseMusic() {
        synchronized(trackLock) {
            lastMusicPosition = currentPosition
            exoPlayer.pause()
            notification.showPause()
            synchronized(focusLock) {
                resumeOnFocusGain = false
            }
            listener?.run {
                if (trackPosition >= 0) {
                    onPause(tracks, trackPosition)
                }
            }
        }
    }

    fun seekTo(position: Float) {
        lastMusicPosition = position
        exoPlayer.seekTo(position)
    }

    fun getTracks(): List<MusicTrack> {
        synchronized(trackLock) {
            return Collections.unmodifiableList(tracks)
        }
    }

    private fun requestAudioFocus() {
        val ret: Int = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            audioManager.requestAudioFocus(audioFocusRequest)
        } else {
            audioManager.requestAudioFocus(this,
                    AudioManager.STREAM_MUSIC, AudioManager.AUDIOFOCUS_GAIN)
        }
        synchronized(focusLock) {
            when (ret) {
                AudioManager.AUDIOFOCUS_REQUEST_FAILED -> playbackDelayed = false
                AudioManager.AUDIOFOCUS_REQUEST_GRANTED -> {
                    playbackDelayed = false
                    playMusic()
                }
                AudioManager.AUDIOFOCUS_REQUEST_DELAYED -> playbackDelayed = true
            }
        }
    }

    override fun onCompletion(exoPlayer: ExoPlayerWrapper) {
        pauseMusic()
        synchronized(trackLock) {
            if (moveOn()) {
                playMusic(youtubeServer.url, tracks, trackPosition + 1)
            } else {
                lastMusicPosition = .0f
            }
        }
    }

    private fun moveOn(): Boolean {
        return trackPosition >= 0 && trackPosition + 1 < tracks.size
    }

    override fun onError(exoPlayer: ExoPlayerWrapper, error: ExoPlaybackException) {
        synchronized(trackLock) {
            if (trackPosition >= 0) {
                listener?.onFailure(Status.ServerOffline, tracks, trackPosition)
                notification.showFailure(tracks[trackPosition])
                if (moveOn()) {
                    playMusic(youtubeServer.url, tracks, trackPosition + 1)
                } else {
                    trackPosition = -1
                }
            }
        }
    }

    override fun onPrepared(exoPlayer: ExoPlayerWrapper) {
        synchronized(trackLock) {
            preparing = false
            requestAudioFocus()
        }
    }

    override fun onAudioFocusChange(focusChange: Int) {
        try {
            when (focusChange) {
                AudioManager.AUDIOFOCUS_GAIN -> if (playbackDelayed || resumeOnFocusGain) {
                    synchronized(focusLock) {
                        playbackDelayed = false
                        resumeOnFocusGain = false
                    }
                    exoPlayer.setVolume(1.0f)
                    playMusic()
                }
                AudioManager.AUDIOFOCUS_LOSS -> {
                    synchronized(focusLock) {
                        resumeOnFocusGain = false
                        playbackDelayed = false
                    }
                    pauseMusic()
                }
                AudioManager.AUDIOFOCUS_LOSS_TRANSIENT, AudioManager.AUDIOFOCUS_LOSS_TRANSIENT_CAN_DUCK -> {
                    synchronized(focusLock) {
                        resumeOnFocusGain = isPlaying
                        playbackDelayed = false
                    }
                    pauseMusic()
                }
            }
        } catch (ignored: IllegalStateException) {
        }

    }

    override fun onDestroy() {
        super.onDestroy()

        notification.stop()

        exoPlayer.release()
        youtubeServer.close()
        unregisterReceiver(receiver)

        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            audioManager.abandonAudioFocus(this)
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        return Service.START_STICKY
    }

    override fun onBind(intent: Intent): IBinder? {
        return binder
    }
}
