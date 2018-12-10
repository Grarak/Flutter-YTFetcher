package com.grarak.flutter.musicplayer

import android.annotation.SuppressLint
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.os.SystemClock
import android.support.v4.media.MediaBrowserCompat
import android.support.v4.media.session.MediaControllerCompat
import android.support.v4.media.session.PlaybackStateCompat
import com.grarak.flutter.musicplayer.network.Gson
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.Registrar
import java.util.*
import java.util.concurrent.atomic.AtomicBoolean
import kotlin.collections.ArrayList

/**
 * MusicplayerPlugin
 */
class MusicplayerPlugin private constructor(private val context: Context,
                                            private val channel: MethodChannel) : MethodCallHandler {

    private interface TransportExecution {
        fun onReady(transportControls: MediaControllerCompat.TransportControls)
    }

    private val mMediaBrowser: MediaBrowserCompat = MediaBrowserCompat(context,
            ComponentName(context, MusicplayerService::class.java),
            MediaBrowserConnectionCallback(), null)

    private val mMediaControllerCallback = MediaControllerCallback()
    private var mMediaController: MediaControllerCompat? = null
    private val mExecutions = ArrayDeque<TransportExecution>()

    private var mCurrentState: PlaybackStateCompat? = null

    private var mClosed = AtomicBoolean()

    private inner class MediaBrowserConnectionCallback : MediaBrowserCompat.ConnectionCallback() {
        override fun onConnected() {
            super.onConnected()

            synchronized(this@MusicplayerPlugin) {
                mMediaController = MediaControllerCompat(context, mMediaBrowser.sessionToken)
                mMediaController!!.registerCallback(mMediaControllerCallback)

                mCurrentState = mMediaController!!.playbackState

                while (mExecutions.size != 0) {
                    mExecutions.poll().onReady(mMediaController!!.transportControls)
                }

                if (mClosed.get()) {
                    mMediaBrowser.disconnect()
                    mMediaController = null
                }
            }
        }
    }

    private inner class MediaControllerCallback : MediaControllerCompat.Callback() {
        @SuppressLint("SwitchIntDef")
        override fun onPlaybackStateChanged(state: PlaybackStateCompat?) {
            super.onPlaybackStateChanged(state)
            synchronized(this@MusicplayerPlugin) {
                mCurrentState = state
                state?.run {
                    mCurrentState = this

                    Log.i("State changed to ${state.state}")

                    val tracks = extras!!.getParcelableArrayList<MusicTrack>("tracks")!!
                    val position = extras!!.getInt("position")

                    when (getState()) {
                        PlaybackStateCompat.STATE_CONNECTING -> {
                            channel.invokeMethod("onPreparing", mapOf(
                                    "tracks" to Gson.listToString(tracks),
                                    "position" to position))
                        }
                        PlaybackStateCompat.STATE_PLAYING -> {
                            channel.invokeMethod("onPlay", mapOf(
                                    "tracks" to Gson.listToString(tracks),
                                    "position" to position))
                        }
                        PlaybackStateCompat.STATE_PAUSED -> {
                            channel.invokeMethod("onPause", mapOf(
                                    "tracks" to Gson.listToString(tracks),
                                    "position" to position))
                        }
                        PlaybackStateCompat.STATE_ERROR -> {
                            channel.invokeMethod("onFailure", mapOf(
                                    "code" to 0,
                                    "tracks" to Gson.listToString(tracks),
                                    "position" to position))
                        }
                        PlaybackStateCompat.STATE_STOPPED -> {
                            unbind()
                            context.stopService(Intent(context, MusicplayerService::class.java))
                            channel.invokeMethod("onDisconnect", null)
                        }
                    }
                }

                if (state == null) {
                    unbind()
                    context.stopService(Intent(context, MusicplayerService::class.java))
                    channel.invokeMethod("onDisconnect", null)
                }
            }
        }

        override fun onSessionDestroyed() {
            super.onSessionDestroyed()

            synchronized(this@MusicplayerPlugin) {
                channel.invokeMethod("onDisconnect", null)
                mMediaController = null
            }
        }
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        if (call.method != "unbind" && call.method != "stop") {
            connect()
        }

        when {
            call.method == "notify" -> {
                execute(object : TransportExecution {
                    override fun onReady(transportControls: MediaControllerCompat.TransportControls) {
                        mMediaControllerCallback.onPlaybackStateChanged(mMediaController!!.playbackState)
                    }
                })
                result.success(null)
            }
            call.method == "playTracks" -> {
                val url = call.argument<String>("url")!!
                val tracks = call.argument<List<HashMap<String, Any>>>("tracks")!!
                val position = call.argument<Int>("position")!!

                val musicTracks = ArrayList<MusicTrack>(tracks.size)
                for (track in tracks) {
                    musicTracks.add(MusicTrack(track["apiKey"] as String, track["title"] as String,
                            track["id"] as String, track["thumbnail"] as String, track["duration"] as String))
                }
                playTracks(url, musicTracks, position)
                result.success(null)
            }
            call.method == "resume" -> {
                execute(object : TransportExecution {
                    override fun onReady(transportControls: MediaControllerCompat.TransportControls) {
                        transportControls.play()
                    }
                })
                result.success(null)
            }
            call.method == "pause" -> {
                execute(object : TransportExecution {
                    override fun onReady(transportControls: MediaControllerCompat.TransportControls) {
                        transportControls.pause()
                    }
                })
                result.success(null)
            }
            call.method == "getDuration" -> {
                execute(object : TransportExecution {
                    override fun onReady(transportControls: MediaControllerCompat.TransportControls) {
                        synchronized(this@MusicplayerPlugin) {
                            if (mCurrentState == null) {
                                result.success(0f)
                            } else {
                                result.success(mCurrentState!!.extras!!.getFloat("duration"))
                            }
                        }
                    }
                })
            }
            call.method == "getPosition" -> {
                execute(object : TransportExecution {
                    override fun onReady(transportControls: MediaControllerCompat.TransportControls) {
                        synchronized(this@MusicplayerPlugin) {
                            if (mCurrentState == null) {
                                result.success(0f)
                            } else {
                                if (mCurrentState!!.state == PlaybackStateCompat.STATE_PLAYING) {
                                    result.success(
                                            (SystemClock.elapsedRealtime() - mCurrentState!!.lastPositionUpdateTime
                                                    + mCurrentState!!.position).toFloat() / 1000)
                                } else {
                                    result.success(mCurrentState!!.position.toFloat() / 1000)
                                }
                            }
                        }
                    }
                })
            }
            call.method == "setPosition" -> {
                val position = call.argument<Double>("position")!!
                execute(object : TransportExecution {
                    override fun onReady(transportControls: MediaControllerCompat.TransportControls) {
                        transportControls.seekTo((position * 1000).toLong())
                        result.success(null)
                    }
                })
            }
            call.method == "getCurrentTrack" -> {
                execute(object : TransportExecution {
                    override fun onReady(transportControls: MediaControllerCompat.TransportControls) {
                        synchronized(this@MusicplayerPlugin) {
                            if (mCurrentState == null) {
                                result.success(null)
                            } else {
                                val tracks = mCurrentState!!.extras!!
                                        .getParcelableArrayList<MusicTrack>("tracks")!!
                                val position = mCurrentState!!.extras!!.getInt("position")
                                result.success(tracks[position])
                            }
                        }
                    }
                })
            }
            call.method == "unbind" || call.method == "stop" -> {
                unbind()
            }
            else -> result.notImplemented()
        }
    }

    private fun playTracks(url: String, tracks: ArrayList<MusicTrack>, position: Int) {
        execute(object : TransportExecution {
            override fun onReady(transportControls: MediaControllerCompat.TransportControls) {
                val bundle = Bundle()
                bundle.putString("url", url)
                bundle.putParcelableArrayList("tracks", tracks)
                bundle.putInt("position", position)
                transportControls.sendCustomAction(MusicplayerService.PLAY_TRACKS, bundle)
            }
        })
    }

    private fun unbind() {
        if (!mClosed.getAndSet(true)) {
            execute(object : TransportExecution {
                override fun onReady(transportControls: MediaControllerCompat.TransportControls) {
                    synchronized(this@MusicplayerPlugin) {
                        mExecutions.clear()
                        mMediaController!!.unregisterCallback(mMediaControllerCallback)
                        mMediaController = null
                        mMediaBrowser.disconnect()
                    }
                }
            })
        }
    }

    @Synchronized
    private fun execute(transportExecution: TransportExecution) {
        if (mMediaController == null) {
            mExecutions.offer(transportExecution)
            return
        }
        transportExecution.onReady(mMediaController!!.transportControls)
    }

    private fun connect() {
        synchronized(this) {
            mClosed.set(false)
            try {
                if (!mMediaBrowser.isConnected) {
                    context.startService(Intent(context, MusicplayerService::class.java))
                    mMediaBrowser.connect()
                }
            } catch (ignored: IllegalStateException) {
            }
        }
    }

    companion object {

        /**
         * Plugin registration.
         */
        @JvmStatic
        fun registerWith(registrar: Registrar) {
            val channel = MethodChannel(registrar.messenger(), "musicplayer")
            channel.setMethodCallHandler(MusicplayerPlugin(registrar.context(), channel))
        }
    }
}
