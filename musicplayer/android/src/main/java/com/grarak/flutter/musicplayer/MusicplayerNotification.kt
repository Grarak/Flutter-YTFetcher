package com.grarak.flutter.musicplayer

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.os.Build
import android.support.annotation.RequiresApi
import android.support.v4.app.NotificationCompat
import com.bumptech.glide.Glide
import com.grarak.flutter.musicplayer.musicplayer.R
import java.util.concurrent.atomic.AtomicBoolean
import java.util.regex.Pattern

class MusicPlayerNotification internal constructor(private val service: MusicplayerService) {
    companion object {
        private const val NOTIFICATION_ID = 1
        private const val NOTIFICATION_CHANNEL = "music_channel"
    }

    private val manager: NotificationManager = service.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

    private val fetching = AtomicBoolean()
    private val playing = AtomicBoolean()
    private var track: MusicTrack? = null
    private var playingBitmap: Bitmap? = null

    init {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            createNotificationChannel()
        }
    }

    private fun getBitmap(url: String): Bitmap {
        return try {
            Glide.with(service).asBitmap().load(url).submit().get()
        } catch (ignored: Exception) {
            return BitmapFactory.decodeResource(service.resources, R.drawable.ic_alert_circle_outline)
        }
    }

    private fun getBroadcast(action: String): PendingIntent {
        return PendingIntent.getBroadcast(service, 0, Intent(action), 0)
    }

    internal fun showProgress(track: MusicTrack) {
        fetching.set(true)
        playing.set(false)
        this.track = track

        val builder = NotificationCompat.Builder(service, NOTIFICATION_CHANNEL)
                .setContentTitle(service.getString(R.string.loading))
                .setContentText(track.title)
                .setSmallIcon(R.drawable.ic_music_box)
                .setProgress(0, 0, true)

        service.startForeground(NOTIFICATION_ID, builder.build())
    }

    internal fun showFailure(track: MusicTrack) {
        fetching.set(false)
        playing.set(false)
        this.track = track

        val builder = NotificationCompat.Builder(service, NOTIFICATION_CHANNEL)
                .setContentTitle(service.getString(R.string.failed))
                .setContentText(track.title)
                .setSmallIcon(R.drawable.ic_music_box)

        manager.notify(NOTIFICATION_ID, builder.build())
        service.stopForeground(false)
    }

    internal fun showPlay(track: MusicTrack) {
        fetching.set(false)
        playing.set(true)
        this.track = track
        Thread {
            playingBitmap = getBitmap(track.thumbnail)
            val builder = baseBuilder(track, playingBitmap!!, true)

            service.startForeground(NOTIFICATION_ID, builder.build())
        }.start()
    }

    internal fun showPause() {
        fetching.set(false)
        playing.set(false)
        track?.run {
            Thread {
                if (playingBitmap == null) {
                    playingBitmap = getBitmap(thumbnail)
                }
                val builder = baseBuilder(this, playingBitmap!!, false)
                        .setAutoCancel(true)

                service.startForeground(NOTIFICATION_ID, builder.build())
            }.start()
        }
    }

    internal fun stop() {
        manager.cancel(NOTIFICATION_ID)
    }

    private fun baseBuilder(
            track: MusicTrack, bitmap: Bitmap, play: Boolean): NotificationCompat.Builder {

        val titleFormatted = formatResultTitle(track)

        val mediaStyle = android.support.v4.media.app.NotificationCompat.DecoratedMediaCustomViewStyle()
        mediaStyle.setShowActionsInCompactView(2)

        return NotificationCompat.Builder(service, NOTIFICATION_CHANNEL)
                .setContentTitle(titleFormatted[0])
                .setContentText(titleFormatted[1])
                .setSubText(track.duration)
                .setSmallIcon(R.drawable.ic_music_box)
                .setLargeIcon(bitmap)
                .addAction(NotificationCompat.Action(
                        if (play) R.drawable.ic_pause else R.drawable.ic_play,
                        service.getString(if (play) R.string.pause else R.string.play),
                        getBroadcast(MusicplayerService.ACTION_MUSIC_PLAY_PAUSE)))
                .addAction(NotificationCompat.Action(
                        R.drawable.ic_skip_next,
                        service.getString(R.string.next),
                        getBroadcast(MusicplayerService.ACTION_MUSIC_NEXT)))
                .addAction(NotificationCompat.Action(
                        R.drawable.ic_stop,
                        service.getString(R.string.stop),
                        getBroadcast(MusicplayerService.ACTION_MUSIC_PLAYER_STOP)))
                .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
                .setPriority(NotificationCompat.PRIORITY_MAX)
                .setStyle(mediaStyle)
    }

    @RequiresApi(api = Build.VERSION_CODES.O)
    private fun createNotificationChannel() {
        if (manager.getNotificationChannel(NOTIFICATION_CHANNEL) != null) {
            return
        }
        val channel = NotificationChannel(
                NOTIFICATION_CHANNEL, service.getString(R.string.music_player),
                NotificationManager.IMPORTANCE_LOW)
        channel.setSound(null, null)

        manager.createNotificationChannel(channel)
    }

    private fun formatResultTitle(track: MusicTrack): Array<String?> {
        val matcher = Pattern.compile("(.+)[:| -] (.+)").matcher(track.title)
        if (matcher.matches()) {
            return arrayOf(matcher.group(1), matcher.group(2))
        }

        var title = track.title
        var contentText = track.id
        if (title.length > 20) {
            val tmp = title.substring(20)
            val whitespaceIndex = tmp.indexOf(' ')
            if (whitespaceIndex >= 0) {
                val firstWhitespace = 20 + tmp.indexOf(' ')
                contentText = title.substring(firstWhitespace + 1)
                title = title.substring(0, firstWhitespace)
            }
        }
        return arrayOf(title, contentText)
    }
}
