package com.grarak.flutter.musicplayer.network

class Youtube : Gson() {

    var apikey: String? = null
    var searchquery: String? = null
    var id: String? = null
    var addhistory: Boolean = false
}
