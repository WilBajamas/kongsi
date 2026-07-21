package com.wilbajamas.kongsi

import android.content.Context
import android.net.ConnectivityManager
import android.net.Network
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.EventChannel

/// Streams network availability to Dart as "online"/"offline". A returning
/// network is what lets SyncBloc flush the outbox without a relaunch.
class ConnectivityStreamHandler(context: Context) : EventChannel.StreamHandler {
    private val connectivityManager =
        context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
    private val mainHandler = Handler(Looper.getMainLooper())
    private var callback: ConnectivityManager.NetworkCallback? = null

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        if (events == null) return
        val networkCallback = object : ConnectivityManager.NetworkCallback() {
            // Callbacks arrive on a binder thread, but the EventSink must be
            // touched on the main thread — hop back before emitting.
            override fun onAvailable(network: Network) {
                mainHandler.post { events.success("online") }
            }

            override fun onLost(network: Network) {
                mainHandler.post { events.success("offline") }
            }
        }
        callback = networkCallback
        connectivityManager.registerDefaultNetworkCallback(networkCallback)
    }

    override fun onCancel(arguments: Any?) {
        callback?.let { connectivityManager.unregisterNetworkCallback(it) }
        callback = null
    }
}
