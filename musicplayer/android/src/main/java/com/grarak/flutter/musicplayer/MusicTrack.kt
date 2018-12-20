package com.grarak.flutter.musicplayer

import android.os.Parcelable
import android.support.v4.media.MediaMetadataCompat
import com.grarak.flutter.musicplayer.network.Gson
import kotlinx.android.parcel.Parcelize
import java.util.regex.Pattern

@Parcelize
class MusicTrack(val apiKey: String, val title: String, val id: String, val thumbnail: String,
                 val duration: String) : Gson(), Parcelable {

    private fun formatResultTitle(): Array<String?> {
        val matcher = Pattern.compile("(.+)[:|-](.+)").matcher(title)
        if (matcher.matches()) {
            return arrayOf(matcher.group(1).trim(), matcher.group(2).trim())
        }

        var title = title
        var contentText = id
        if (title.length > 20) {
            val tmp = title.substring(20)
            val whitespaceIndex = tmp.indexOf(' ')
            if (whitespaceIndex >= 0) {
                val firstWhitespace = 20 + tmp.indexOf(' ')
                contentText = title.substring(firstWhitespace + 1)
                title = title.substring(0, firstWhitespace)
            }
        }
        return arrayOf(contentText, title)
    }

    fun toMap(): Map<String, String> {
        return mapOf("apiKey" to apiKey, "title" to title,
                "id" to id, "thumbnail" to thumbnail, "duration" to duration)
    }

    fun toMetadataBuilder(): MediaMetadataCompat.Builder {
        val titles = formatResultTitle()
        val durations = duration.split(":")
        val calculatedDuration = (durations[0].toInt() * 60 + durations[1].toInt()) * 60L * 1000

        return MediaMetadataCompat.Builder().apply {
            putString(MediaMetadataCompat.METADATA_KEY_MEDIA_ID, id)
            putString(MediaMetadataCompat.METADATA_KEY_ARTIST, titles[0])
            putString(MediaMetadataCompat.METADATA_KEY_TITLE, titles[1])
            putLong(MediaMetadataCompat.METADATA_KEY_DURATION, calculatedDuration)
        }
    }
}
