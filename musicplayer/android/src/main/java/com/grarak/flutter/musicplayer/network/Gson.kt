package com.grarak.flutter.musicplayer.network

import com.google.gson.GsonBuilder
import java.io.Serializable

abstract class Gson : Serializable {

    override fun toString(): String {
        return GsonBuilder().create().toJson(this)
    }

    override fun equals(other: Any?): Boolean {
        return other is Gson && toString() == other.toString()
    }

    override fun hashCode(): Int {
        return javaClass.hashCode()
    }

    companion object {
        fun listToString(list: List<Gson>): List<String> {
            val stringList = ArrayList<String>()
            for (json in list) {
                stringList.add(json.toString())
            }
            return stringList
        }
    }
}
