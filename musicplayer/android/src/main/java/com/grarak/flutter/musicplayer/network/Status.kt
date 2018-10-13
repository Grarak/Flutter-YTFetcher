package com.grarak.flutter.musicplayer.network

import com.google.gson.JsonParser

object Status {
    const val ServerOffline = -1
    const val NoError = 0
    const val Invalid = 1
    const val NameShort = 2
    const val PasswordShort = 3
    const val PasswordInvalid = 4
    const val NameInvalid = 5
    const val AddUserFailed = 6
    const val UserAlreadyExists = 7
    const val InvalidPassword = 8
    const val PasswordLong = 9
    const val NameLong = 10
    const val YoutubeFetchFailure = 11
    const val YoutubeSearchFailure = 12
    const val YoutubeGetFailure = 13
    const val YoutubeGetInfoFailure = 14
    const val YoutubeGetChartsFailure = 15
    const val PlaylistIdAlreadyExists = 16
    const val AddHistoryFailed = 17

    fun getStatusCode(json: String): Int? {
        return try {
            JsonParser().parse(json).asJsonObject.get("statuscode").asInt
        } catch (ignored: Exception) {
            null
        }
    }
}
