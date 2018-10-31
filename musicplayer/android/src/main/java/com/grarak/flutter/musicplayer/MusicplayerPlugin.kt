package com.grarak.flutter.musicplayer

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.ServiceConnection
import android.os.IBinder
import com.grarak.flutter.musicplayer.network.Gson
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.Registrar
import java.util.concurrent.LinkedBlockingQueue

/**
 * MusicplayerPlugin
 */
class MusicplayerPlugin private constructor(private val context: Context,
                                            private val channel: MethodChannel) : MethodCallHandler {

    private var service: MusicplayerService? = null
    private val callingQueue = LinkedBlockingQueue<Runnable>()

    private var closed: Boolean = false

    private val listener = object : MusicPlayerListener {
        override fun onPreparing(tracks: List<MusicTrack>, position: Int) {
            channel.invokeMethod("onPreparing", mapOf("tracks" to Gson.listToString(tracks),
                    "position" to position))
        }

        override fun onFailure(code: Int, tracks: List<MusicTrack>, position: Int) {
            channel.invokeMethod("onFailure", mapOf("code" to code, "tracks" to Gson.listToString(tracks),
                    "position" to position))
        }

        override fun onPlay(tracks: List<MusicTrack>, position: Int) {
            channel.invokeMethod("onPlay", mapOf("tracks" to Gson.listToString(tracks),
                    "position" to position))
        }

        override fun onPause(tracks: List<MusicTrack>, position: Int) {
            channel.invokeMethod("onPause", mapOf("tracks" to Gson.listToString(tracks),
                    "position" to position))
        }

        override fun onDisconnect() {
            service?.pauseMusic()
            unbind()
            context.stopService(Intent(context, MusicplayerService::class.java))
            channel.invokeMethod("onDisconnect", null)
        }
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        waitForService()

        when {
            call.method == "notify" -> {
                notifyListener()
            }
            call.method == "playTracks" -> {
                val url = call.argument<String>("url")
                val tracks = call.argument<List<HashMap<String, Any>>>("tracks")
                val position = call.argument<Int>("position")
                playTracks(url!!, tracks!!, position!!)
                result.success(null)
            }
            call.method == "resume" -> {
                resume()
            }
            call.method == "pause" -> {
                pause()
            }
            call.method == "getDuration" -> {
                executeCall(Runnable {
                    result.success(service!!.duration)
                })
            }
            call.method == "getPosition" -> {
                executeCall(Runnable {
                    result.success(service!!.currentPosition)
                })
            }
            call.method == "unbind" -> {
                unbind()
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    private val serviceConnection = object : ServiceConnection {
        override fun onServiceConnected(p0: ComponentName?, p1: IBinder?) {
            Log.i(MusicplayerService::class.java.simpleName + " connected")

            service = (p1 as MusicplayerService.MusicPlayerBinder).service

            if (closed) {
                context.unbindService(this)
                service = null
            } else {
                service?.listener = listener
                while (callingQueue.size != 0) {
                    callingQueue.poll().run()
                }
            }
        }

        override fun onServiceDisconnected(p0: ComponentName?) {
            Log.i(MusicplayerService::class.java.simpleName + " disconnected")
            service = null
        }
    }

    private fun waitForService() {
        if (service == null) {
            closed = false
            Intent(context, MusicplayerService::class.java).apply {
                Log.i("Binding " + MusicplayerService::class.java.simpleName)
                context.startService(this)
                context.bindService(this, serviceConnection, Context.BIND_AUTO_CREATE)
            }
        }
    }

    private fun notifyListener() {
        executeCall(Runnable {
            service!!.let {
                if (it.isPlaying) {
                    listener.onPlay(it.getTracks(), it.trackPosition)
                } else if (it.isPreparing) {
                    listener.onPreparing(it.getTracks(), it.trackPosition)
                } else {
                    val tracks = it.getTracks()
                    if (tracks.isNotEmpty()
                            && it.trackPosition >= 0
                            && it.trackPosition < tracks.size) {
                        listener.onPause(tracks, it.trackPosition)
                    } else {
                        channel.invokeMethod("onDisconnect", null)
                    }
                }
            }
        })
    }

    private fun playTracks(url: String, tracks: List<HashMap<String, Any>>, position: Int) {
        executeCall(Runnable {
            val musicTracks = ArrayList<MusicTrack>(tracks.size)
            for (track in tracks) {
                musicTracks.add(MusicTrack(track["apiKey"] as String, track["title"] as String,
                        track["id"] as String, track["thumbnail"] as String, track["duration"] as String))
            }

            service!!.run {
                playMusic(url, musicTracks, position)
            }
        })
    }

    private fun resume() {
        executeCall(Runnable {
            service!!.resumeMusic()
        })
    }

    private fun pause() {
        executeCall(Runnable {
            service!!.pauseMusic()
        })
    }

    private fun unbind() {
        closed = true
        if (service != null) {
            try {
                service!!.listener = null
                context.unbindService(serviceConnection)
            } catch (ignored: IllegalArgumentException) {
            }
            service = null
        }
    }

    private fun executeCall(runnable: Runnable) {
        if (closed) {
            return
        }

        if (service != null) {
            runnable.run()
        } else {
            callingQueue.offer(runnable)
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
