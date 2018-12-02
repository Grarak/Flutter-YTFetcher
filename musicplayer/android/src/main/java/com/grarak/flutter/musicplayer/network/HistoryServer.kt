package com.grarak.flutter.musicplayer.network

class HistoryServer : Server("") {

    fun add(history: History) {
        post(getApiUrl("users/history/add"), history.toString(), null)
    }

}