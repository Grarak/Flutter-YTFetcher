package com.grarak.flutter.musicplayer

import android.content.Context
import android.net.Uri
import android.os.PowerManager
import com.google.android.exoplayer2.*
import com.google.android.exoplayer2.audio.AudioAttributes
import com.google.android.exoplayer2.source.ExtractorMediaSource
import com.google.android.exoplayer2.source.TrackGroupArray
import com.google.android.exoplayer2.trackselection.DefaultTrackSelector
import com.google.android.exoplayer2.trackselection.TrackSelectionArray
import com.google.android.exoplayer2.upstream.DataSource
import com.google.android.exoplayer2.upstream.DefaultDataSourceFactory
import com.google.android.exoplayer2.util.Util
import java.io.File

class ExoPlayerWrapper(context: Context) : Player.EventListener {

    private val exoPlayer: SimpleExoPlayer
    private val dataSourceFactory: DataSource.Factory
    private val wakeLock: PowerManager.WakeLock

    private val stateLock = Any()
    private var state = State.IDLE

    var onPlayerListener: OnPlayerListener? = null

    val currentPosition: Float
        get() = exoPlayer.currentPosition.toFloat() / 1000

    val duration: Float
        get() = exoPlayer.duration.toFloat() / 1000

    val isPlaying: Boolean
        get() = getState() == State.PLAYING

    private enum class State {
        PREPARING,
        PLAYING,
        PAUSED,
        IDLE
    }

    interface OnPlayerListener {
        fun onPrepared(exoPlayer: ExoPlayerWrapper)

        fun onSeekComplete(exoPlayer: ExoPlayerWrapper)

        fun onCompletion(exoPlayer: ExoPlayerWrapper)

        fun onError(exoPlayer: ExoPlayerWrapper, error: ExoPlaybackException)
    }

    init {
        val renderersFactory = DefaultRenderersFactory(context,
                DefaultRenderersFactory.EXTENSION_RENDERER_MODE_ON)
        exoPlayer = ExoPlayerFactory.newSimpleInstance(context, renderersFactory, DefaultTrackSelector())
        exoPlayer.addListener(this)
        dataSourceFactory = DefaultDataSourceFactory(context,
                Util.getUserAgent(context, "MusicplayerPlugin"))

        val powerManager = context.getSystemService(Context.POWER_SERVICE) as PowerManager
        wakeLock = powerManager.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK,
                ExoPlayerWrapper::class.java.simpleName)
    }

    fun setUrl(url: String) {
        setState(State.PREPARING)
        val mediaSource = ExtractorMediaSource.Factory(dataSourceFactory)
                .createMediaSource(Uri.parse(url))
        exoPlayer.prepare(mediaSource, true, true)
    }

    fun setFile(file: File) {
        setState(State.PREPARING)
        val mediaSource = ExtractorMediaSource.Factory(dataSourceFactory)
                .createMediaSource(Uri.fromFile(file))
        exoPlayer.prepare(mediaSource, true, true)
    }

    fun seekTo(position: Float) {
        exoPlayer.seekTo((position * 1000).toLong())
    }

    fun setAudioAttributes(audioAttributes: AudioAttributes) {
        exoPlayer.audioAttributes = audioAttributes
    }

    fun setVolume(volume: Float) {
        exoPlayer.volume = volume
    }

    fun play() {
        setState(State.PLAYING)
        exoPlayer.seekTo(exoPlayer.currentPosition)
        exoPlayer.playWhenReady = true
    }

    fun pause() {
        setState(State.PAUSED)
        exoPlayer.playWhenReady = false
    }

    fun stop() {
        setState(State.IDLE)
        exoPlayer.stop()
    }

    fun release() {
        if (wakeLock.isHeld) {
            wakeLock.release()
        }
        exoPlayer.release()
    }

    override fun onTimelineChanged(timeline: Timeline, manifest: Any?, reason: Int) {}

    override fun onTracksChanged(trackGroups: TrackGroupArray, trackSelections: TrackSelectionArray) {}

    override fun onLoadingChanged(isLoading: Boolean) {}

    override fun onPlayerStateChanged(playWhenReady: Boolean, playbackState: Int) {
        when (playbackState) {
            Player.STATE_READY -> if (getState() == State.PREPARING) {
                setState(State.IDLE)
                onPlayerListener?.onPrepared(this)
            }
            Player.STATE_ENDED -> if (playWhenReady && (duration == .0f || currentPosition != .0f)) {
                setState(State.IDLE)
                onPlayerListener?.onCompletion(this)
            }
        }
    }

    override fun onRepeatModeChanged(repeatMode: Int) {}

    override fun onShuffleModeEnabledChanged(shuffleModeEnabled: Boolean) {}

    override fun onPlayerError(error: ExoPlaybackException) {
        onPlayerListener?.onError(this, error)
    }

    override fun onPositionDiscontinuity(reason: Int) {}

    override fun onPlaybackParametersChanged(playbackParameters: PlaybackParameters) {}

    override fun onSeekProcessed() {
        onPlayerListener?.onSeekComplete(this)
    }

    private fun setState(state: State) {
        synchronized(stateLock) {
            this.state = state
            if (state == State.PLAYING) {
                wakeLock.acquire()
            } else if (wakeLock.isHeld) {
                wakeLock.release()
            }
        }
    }

    private fun getState(): State {
        synchronized(stateLock) {
            return state
        }
    }
}