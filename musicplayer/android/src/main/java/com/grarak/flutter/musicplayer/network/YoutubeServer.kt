package com.grarak.flutter.musicplayer.network

import java.net.HttpURLConnection
import java.net.URLEncoder

class YoutubeServer : Server("") {

    interface YoutubeSongIdCallback {
        fun onSuccess(url: String)

        fun onFailure(code: Int)
    }

    fun fetchSong(youtube: Youtube, youtubeSongIdCallback: YoutubeSongIdCallback) {
        post(getApiUrl("youtube/fetch"), youtube.toString(), object : Request.RequestCallback {
            override fun onConnect(request: Request, status: Int, url: String): Boolean {
                return true
            }

            override fun onSuccess(request: Request, status: Int,
                                   headers: Map<String, List<String>>, response: String) {
                if (status == HttpURLConnection.HTTP_OK) {
                    if (headers.containsKey("ytfetcher-id")) {
                        verifyFetchedSong(response.trim { it <= ' ' },
                                headers["ytfetcher-id"]!![0], youtubeSongIdCallback)
                    } else {
                        youtubeSongIdCallback.onSuccess(response)
                    }
                } else {
                    youtubeSongIdCallback.onFailure(parseStatusCode(response))
                }
            }

            override fun onFailure(request: Request, e: Exception?) {
                youtubeSongIdCallback.onFailure(Status.ServerOffline)
            }
        })
    }

    private fun verifyFetchedSong(url: String, id: String, youtubeSongIdCallback: YoutubeSongIdCallback) {
        get(url, object : Request.RequestCallback {

            private val newUrl = (getApiUrl("youtube/get?id=")
                    + URLEncoder.encode(id)
                    + "&url=" + URLEncoder.encode(url))

            override fun onConnect(request: Request, status: Int, url: String): Boolean {
                if (status in 200..299) {
                    youtubeSongIdCallback.onSuccess(url)
                } else {
                    verifyForwardedSong()
                }
                return false
            }

            override fun onSuccess(request: Request, status: Int, headers: Map<String, List<String>>, response: String) {}

            override fun onFailure(request: Request, e: Exception?) {
                verifyForwardedSong()
            }

            private fun verifyForwardedSong() {
                get(newUrl, object : Request.RequestCallback {
                    override fun onConnect(request: Request, status: Int, url: String): Boolean {
                        youtubeSongIdCallback.onSuccess(url)
                        return false
                    }

                    override fun onSuccess(request: Request, status: Int, headers: Map<String, List<String>>, response: String) {}

                    override fun onFailure(request: Request, e: Exception?) {
                        youtubeSongIdCallback.onFailure(Status.ServerOffline)
                    }
                })
            }
        })
    }
}
