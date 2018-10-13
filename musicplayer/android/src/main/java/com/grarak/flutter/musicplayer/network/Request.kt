package com.grarak.flutter.musicplayer.network

import android.os.Handler
import android.os.Looper
import java.io.Closeable
import java.io.DataOutputStream
import java.io.IOException
import java.net.HttpURLConnection
import java.net.URL
import java.util.concurrent.atomic.AtomicBoolean

class Request internal constructor() : Closeable {

    private var connection: HttpURLConnection? = null
    private val handler: Handler = Handler(Looper.getMainLooper())
    private val closed = AtomicBoolean()

    interface RequestCallback {
        fun onConnect(request: Request, status: Int, url: String)

        fun onSuccess(request: Request, status: Int,
                      headers: Map<String, List<String>>, response: String)

        fun onFailure(request: Request, e: Exception?)
    }

    internal fun doRequest(url: String, contentType: String?,
                           data: String?, requestCallback: RequestCallback) {
        closed.set(false)
        var outputStream: DataOutputStream? = null

        try {
            connection = URL(url).openConnection() as HttpURLConnection
            connection!!.run {
                connectTimeout = 3000
                instanceFollowRedirects = false
                if (contentType != null) {
                    setRequestProperty("Content-Type", contentType)
                }
                if (data != null) {
                    requestMethod = "POST"
                    doOutput = true
                } else {
                    requestMethod = "GET"
                }
                connect()

                if (data != null) {
                    outputStream = DataOutputStream(getOutputStream())
                    outputStream!!.run {
                        writeBytes(data)
                        flush()
                    }
                }

                val statusCode = responseCode
                when (statusCode) {
                    HttpURLConnection.HTTP_MOVED_PERM,
                    HttpURLConnection.HTTP_MOVED_TEMP,
                    HttpURLConnection.HTTP_SEE_OTHER -> {
                        val newUrl = getHeaderField("Location")
                        if (newUrl == null) {
                            handler.post { requestCallback.onFailure(this@Request, null) }
                        } else {
                            doRequest(newUrl, contentType, data, requestCallback)
                        }
                        return
                    }
                }

                handler.post { requestCallback.onConnect(this@Request, statusCode, url) }
                val inputStream = if (statusCode < 200 || statusCode >= 300) errorStream else inputStream

                val response = inputStream.bufferedReader().use {
                    it.readText()
                }

                handler.post {
                    requestCallback.onSuccess(this@Request, statusCode,
                            connection!!.headerFields, response)
                }
            }
        } catch (e: IOException) {
            if (!closed.get()) {
                handler.post { requestCallback.onFailure(this, e) }
            }
        } finally {
            connection?.disconnect()

            try {
                outputStream?.close()
            } catch (ignored: IOException) {
            }
        }
    }

    override fun close() {
        closed.set(true)
        Thread {
            connection?.disconnect()
        }.start()
    }
}
