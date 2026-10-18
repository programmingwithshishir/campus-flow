package com.example.campus_flow

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import org.json.JSONArray
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class RoutineWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        updateWidgets(context, appWidgetManager, appWidgetIds)
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)

        when (intent.action) {
            ACTION_TOGGLE_ROUTINE -> {
                val routineId = intent.getStringExtra(EXTRA_ROUTINE_ID) ?: return
                toggleRoutine(context, routineId)
                updateAll(context)
                MainActivity.notifyWidgetRoutineUpdated()
            }
            Intent.ACTION_DATE_CHANGED,
            Intent.ACTION_TIME_CHANGED,
            Intent.ACTION_TIMEZONE_CHANGED -> {
                updateAll(context)
            }
        }
    }

    companion object {
        private const val ROUTINES_KEY = MainActivity.ROUTINES_KEY
        private const val PREFS_NAME = MainActivity.PREFS_NAME
        const val ACTION_TOGGLE_ROUTINE = "com.example.campus_flow.ACTION_TOGGLE_ROUTINE"
        const val EXTRA_ROUTINE_ID = "extra_routine_id"

        fun updateAll(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val componentName = ComponentName(context, RoutineWidgetProvider::class.java)
            val appWidgetIds = manager.getAppWidgetIds(componentName)
            updateWidgets(context, manager, appWidgetIds)
            manager.notifyAppWidgetViewDataChanged(appWidgetIds, R.id.routine_list)
        }

        private fun updateWidgets(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
            for (appWidgetId in appWidgetIds) {
                val views = RemoteViews(context.packageName, R.layout.routine_widget)

                val serviceIntent = Intent(context, RoutineWidgetService::class.java)
                views.setRemoteAdapter(R.id.routine_list, serviceIntent)
                views.setEmptyView(R.id.routine_list, R.id.empty_routine_view)

                val toggleIntent = Intent(context, RoutineWidgetProvider::class.java).apply {
                    action = ACTION_TOGGLE_ROUTINE
                }
                val togglePendingIntent = PendingIntent.getBroadcast(
                    context,
                    0,
                    toggleIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE,
                )
                views.setPendingIntentTemplate(R.id.routine_list, togglePendingIntent)

                val openAppIntent = Intent(context, MainActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                }
                val openAppPendingIntent = PendingIntent.getActivity(
                    context,
                    2,
                    openAppIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
                )
                views.setOnClickPendingIntent(R.id.empty_routine_view, openAppPendingIntent)
                views.setOnClickPendingIntent(R.id.widget_header_title, openAppPendingIntent)

                appWidgetManager.updateAppWidget(appWidgetId, views)
                appWidgetManager.notifyAppWidgetViewDataChanged(appWidgetId, R.id.routine_list)
            }
        }

        private fun toggleRoutine(context: Context, routineId: String) {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val encodedRoutines = prefs.getString(ROUTINES_KEY, "[]") ?: "[]"
            val array = JSONArray(encodedRoutines)
            val todayStr = SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date())

            for (index in 0 until array.length()) {
                val item = array.getJSONObject(index)
                if (item.optString("id") == routineId) {
                    val lastCompleted = if (item.isNull("lastCompletedDate")) null else item.optString("lastCompletedDate")
                    if (lastCompleted == todayStr) {
                        item.put("lastCompletedDate", JSONObject.NULL)
                    } else {
                        item.put("lastCompletedDate", todayStr)
                    }
                    break
                }
            }

            prefs.edit().putString(ROUTINES_KEY, array.toString()).apply()
        }
    }
}
