package com.grarak.flutter.musicplayer

import com.grarak.flutter.musicplayer.network.Gson

class MusicTrack(val apiKey: String, val title: String, val id: String, val thumbnail: String, val duration: String) : Gson()
