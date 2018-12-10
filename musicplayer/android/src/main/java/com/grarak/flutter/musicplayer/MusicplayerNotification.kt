package com.grarak.flutter.musicplayer

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.os.Build
import android.support.v4.app.NotificationCompat
import android.support.v4.media.MediaMetadataCompat
import android.support.v4.media.session.MediaButtonReceiver
import android.support.v4.media.session.MediaSessionCompat
import android.support.v4.media.session.PlaybackStateCompat
import com.bumptech.glide.Glide
import com.grarak.flutter.musicplayer.musicplayer.R
import java.lang.ref.WeakReference
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit

class MusicplayerNotification(private val mService: MusicplayerService) {

    private val mExecutor = Executors.newSingleThreadExecutor()

    init {
        val manager = mService.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.cancelAll()
    }

    fun showNotification(musicTrack: MusicTrack, state: PlaybackStateCompat,
                         session: MediaSessionCompat) {
        mExecutor.submit(Loader(WeakReference(mService), musicTrack, state, session))
    }

    fun destroy() {
        mService.stopForeground(true)
    }

    private class Loader(private val mServiceRef: WeakReference<MusicplayerService>,
                         private val mMusicTrack: MusicTrack,
                         private val mState: PlaybackStateCompat,
                         private val mSession: MediaSessionCompat) : Runnable {

        private fun getBitmap(context: Context, url: String): Bitmap {
            return try {
                Glide.with(context).asBitmap().load(url).submit().get(250, TimeUnit.MILLISECONDS)
            } catch (ignored: Exception) {
                return BitmapFactory.decodeResource(context.resources, R.drawable.ic_alert_circle_outline)
            }
        }

        private fun buildNotification(context: Context): Notification? {
            val intent = context.packageManager.getLaunchIntentForPackage("com.grarak.flutter.ytfetcher")!!
            intent.setPackage(null)

            val contentIntent = PendingIntent.getActivity(context, 0, intent, 0)

            val bitmap = getBitmap(context, mMusicTrack.thumbnail)

            when (mState.state) {
                PlaybackStateCompat.STATE_CONNECTING -> {
                    return NotificationCompat.Builder(context, NOTIFICATION_CHANNEL)
                            .setContentTitle(context.getString(R.string.loading))
                            .setContentText(mMusicTrack.title)
                            .setSmallIcon(R.drawable.ic_music_box)
                            .setLargeIcon(bitmap)
                            .setProgress(0, 0, true)
                            .setContentIntent(contentIntent)
                            .build()
                }
                PlaybackStateCompat.STATE_PLAYING, PlaybackStateCompat.STATE_PAUSED -> {
                    val metadata = mMusicTrack.toMetadataBuilder()
                            .putBitmap(MediaMetadataCompat.METADATA_KEY_ART, bitmap)
                            .build()
                    mSession.setMetadata(metadata)

                    val description = metadata.description

                    val builder = NotificationCompat.Builder(context, NOTIFICATION_CHANNEL)
                    builder.setSmallIcon(R.drawable.ic_music_box)
                            .setContentTitle(description.title)
                            .setContentText(description.subtitle)
                            .setLargeIcon(bitmap)
                            .setContentIntent(contentIntent)
                            .setDeleteIntent(MediaButtonReceiver.buildMediaButtonPendingIntent(
                                    context, PlaybackStateCompat.ACTION_STOP))
                            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)

                    var actions = 1
                    // If skip to next action is enabled.
                    if (mState.actions and PlaybackStateCompat.ACTION_SKIP_TO_PREVIOUS != 0L) {
                        actions++
                        builder.addAction(NotificationCompat.Action(
                                R.drawable.ic_skip_previous,
                                context.getString(R.string.previous),
                                MediaButtonReceiver.buildMediaButtonPendingIntent(
                                        context,
                                        PlaybackStateCompat.ACTION_SKIP_TO_PREVIOUS)))
                    }

                    builder.addAction(if (mState.state == PlaybackStateCompat.STATE_PLAYING) {
                        NotificationCompat.Action(
                                R.drawable.ic_pause,
                                context.getString(R.string.pause),
                                MediaButtonReceiver.buildMediaButtonPendingIntent(
                                        context,
                                        PlaybackStateCompat.ACTION_PAUSE))
                    } else {
                        NotificationCompat.Action(
                                R.drawable.ic_play,
                                context.getString(R.string.play),
                                MediaButtonReceiver.buildMediaButtonPendingIntent(
                                        context,
                                        PlaybackStateCompat.ACTION_PLAY))
                    })

                    // If skip to prev action is enabled.
                    if (mState.actions and PlaybackStateCompat.ACTION_SKIP_TO_NEXT != 0L) {
                        actions++
                        builder.addAction(NotificationCompat.Action(
                                R.drawable.ic_skip_next,
                                context.getString(R.string.next),
                                MediaButtonReceiver.buildMediaButtonPendingIntent(
                                        context,
                                        PlaybackStateCompat.ACTION_SKIP_TO_NEXT)))
                    }

                    val args = IntArray(actions)
                    for (i in 0 until actions) {
                        args[i] = i
                    }

                    builder.setStyle(android.support.v4.media.app.NotificationCompat.MediaStyle()
                            .setMediaSession(mSession.sessionToken)
                            .setShowActionsInCompactView(*args)
                            .setShowCancelButton(true)
                            .setCancelButtonIntent(
                                    MediaButtonReceiver.buildMediaButtonPendingIntent(context,
                                            PlaybackStateCompat.ACTION_STOP)))

                    return builder.build()
                }
                PlaybackStateCompat.STATE_ERROR -> {
                    return NotificationCompat.Builder(context, NOTIFICATION_CHANNEL)
                            .setContentTitle(context.getString(R.string.failed))
                            .setContentText(mMusicTrack.title)
                            .setSmallIcon(R.drawable.ic_music_box)
                            .setLargeIcon(bitmap)
                            .setContentIntent(contentIntent)
                            .build()
                }
            }
            return null
        }

        override fun run() {
            val service = mServiceRef.get()
            service?.run {
                val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O
                        && manager.getNotificationChannel(NOTIFICATION_CHANNEL) == null) {
                    val channel = NotificationChannel(
                            NOTIFICATION_CHANNEL, service.getString(R.string.music_player),
                            NotificationManager.IMPORTANCE_LOW)
                    channel.setSound(null, null)

                    manager.createNotificationChannel(channel)
                }

                val notification = buildNotification(this)
                notification?.let {
                    when (mState.state) {
                        PlaybackStateCompat.STATE_CONNECTING, PlaybackStateCompat.STATE_PLAYING -> {
                            startForeground(NOTIFICATION_ID, it)
                        }
                        PlaybackStateCompat.STATE_PAUSED, PlaybackStateCompat.STATE_ERROR -> {
                            stopForeground(false)
                            manager.notify(NOTIFICATION_ID, it)
                        }
                    }
                }
            }
        }
    }

    companion object {
        private const val NOTIFICATION_ID = 1
        private const val NOTIFICATION_CHANNEL = "music_channel"
    }
}
