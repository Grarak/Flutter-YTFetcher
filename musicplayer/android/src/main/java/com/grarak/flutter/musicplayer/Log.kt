package com.grarak.flutter.musicplayer

object Log {

    private const val TAG = "MusicplayerPlugin"

    fun i(message: String?) {
        android.util.Log.i(TAG, getMessage(message))
    }

    private fun getMessage(message: String?): String {
        val element = Thread.currentThread().stackTrace[4]
        val className = element.className

        return String.format("[%s][%s] %s",
                className.substring(className.lastIndexOf(".") + 1),
                element.methodName,
                message)
    }
}