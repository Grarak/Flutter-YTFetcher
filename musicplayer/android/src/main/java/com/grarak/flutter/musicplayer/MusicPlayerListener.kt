package com.grarak.flutter.musicplayer

interface MusicPlayerListener {
    fun onPreparing(tracks: List<MusicTrack>, position: Int)

    fun onFailure(code: Int, tracks: List<MusicTrack>, position: Int)

    fun onPlay(tracks: List<MusicTrack>, position: Int)

    fun onPause(tracks: List<MusicTrack>, position: Int)

    fun onDisconnect()
}