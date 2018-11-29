package com.grarak.flutter.musicplayer

import com.grarak.flutter.musicplayer.network.Gson

class MusicTrack(val apiKey: String, val title: String, val id: String, val thumbnail: String, val duration: String) : Gson() {
    fun toMap(): Map<String, String> {
        return mapOf("apiKey" to apiKey, "title" to title,
                "id" to id, "thumbnail" to thumbnail, "duration" to duration)
    }
}
