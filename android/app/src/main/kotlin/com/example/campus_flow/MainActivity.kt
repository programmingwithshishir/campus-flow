package com.example.campus_flow

import android.content.Context
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var channel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val ch = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_NAME)
        channel = ch
        instance = this

        ch.setMethodCallHandler { call, result ->
            when (call.method) {
                "loadTasks" -> {
                    val tasks = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE).getString(TASKS_KEY, "[]")
                    result.success(tasks)
                }
                "saveTasks" -> {
                    val tasks = call.argument<String>("tasks") ?: "[]"
                    getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE).edit().putString(TASKS_KEY, tasks).apply()
                    TaskWidgetProvider.updateAll(this)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onDestroy() {
        if (instance == this) {
            instance = null
        }
        channel = null
        super.onDestroy()
    }

    companion object {
        const val CHANNEL_NAME = "campus_flow.widget_sync"
        const val PREFS_NAME = "campus_flow_widget_store"
        const val TASKS_KEY = "tasks"

        private var instance: MainActivity? = null

        fun notifyWidgetTaskUpdated() {
            Handler(Looper.getMainLooper()).post {
                instance?.channel?.invokeMethod("onWidgetTaskUpdated", null)
            }
        }
    }
}
