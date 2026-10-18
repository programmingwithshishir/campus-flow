package com.example.campus_flow

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import org.json.JSONArray

class TaskWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        updateWidgets(context, appWidgetManager, appWidgetIds)
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)

        when (intent.action) {
            ACTION_TOGGLE_TASK -> {
                val taskId = intent.getStringExtra(EXTRA_TASK_ID) ?: return
                toggleTask(context, taskId)
                updateAll(context)
                MainActivity.notifyWidgetTaskUpdated()
            }
            Intent.ACTION_DATE_CHANGED,
            Intent.ACTION_TIME_CHANGED,
            Intent.ACTION_TIMEZONE_CHANGED -> {
                updateAll(context)
            }
        }
    }

    companion object {
        private const val TASKS_KEY = MainActivity.TASKS_KEY
        private const val PREFS_NAME = MainActivity.PREFS_NAME
        const val ACTION_TOGGLE_TASK = "com.example.campus_flow.ACTION_TOGGLE_TASK"
        const val EXTRA_TASK_ID = "extra_task_id"

        fun updateAll(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val componentName = ComponentName(context, TaskWidgetProvider::class.java)
            val appWidgetIds = manager.getAppWidgetIds(componentName)
            updateWidgets(context, manager, appWidgetIds)
            manager.notifyAppWidgetViewDataChanged(appWidgetIds, R.id.task_list)
        }

        private fun updateWidgets(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
            for (appWidgetId in appWidgetIds) {
                val views = RemoteViews(context.packageName, R.layout.task_widget)

                val serviceIntent = Intent(context, TaskWidgetService::class.java)
                views.setRemoteAdapter(R.id.task_list, serviceIntent)
                views.setEmptyView(R.id.task_list, R.id.empty_view)

                val toggleIntent = Intent(context, TaskWidgetProvider::class.java).apply {
                    action = ACTION_TOGGLE_TASK
                }
                val togglePendingIntent = PendingIntent.getBroadcast(
                    context,
                    0,
                    toggleIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE,
                )
                views.setPendingIntentTemplate(R.id.task_list, togglePendingIntent)

                val openAppIntent = Intent(context, MainActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                }
                val openAppPendingIntent = PendingIntent.getActivity(
                    context,
                    1,
                    openAppIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
                )
                views.setOnClickPendingIntent(R.id.empty_view, openAppPendingIntent)
                views.setOnClickPendingIntent(R.id.widget_header_title, openAppPendingIntent)

                appWidgetManager.updateAppWidget(appWidgetId, views)
                appWidgetManager.notifyAppWidgetViewDataChanged(appWidgetId, R.id.task_list)
            }
        }

        private fun readTasks(context: Context): List<TaskRecord> {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val encodedTasks = prefs.getString(TASKS_KEY, "[]") ?: "[]"
            val array = JSONArray(encodedTasks)
            val tasks = mutableListOf<TaskRecord>()

            for (index in 0 until array.length()) {
                val item = array.getJSONObject(index)
                tasks.add(
                    TaskRecord(
                        id = item.getString("id"),
                        title = item.getString("title"),
                        priority = item.getString("priority"),
                        createdAt = item.getString("createdAt"),
                        isCompleted = item.optBoolean("isCompleted", false),
                    ),
                )
            }

            return tasks
        }

        private fun toggleTask(context: Context, taskId: String) {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val currentTasks = sortTasks(readTasks(context))
            val taskIndex = currentTasks.indexOfFirst { it.id == taskId }

            if (taskIndex == -1) {
                return
            }

            currentTasks[taskIndex] = currentTasks[taskIndex].copy(isCompleted = !currentTasks[taskIndex].isCompleted)
            sortTasks(currentTasks)
            prefs.edit().putString(TASKS_KEY, encodeTasks(currentTasks)).apply()
        }

        private fun sortTasks(tasks: List<TaskRecord>): MutableList<TaskRecord> {
            val sortedTasks = tasks.toMutableList()
            sortedTasks.sortWith(
                compareBy<TaskRecord> { it.isCompleted }
                    .thenByDescending { priorityWeight(it.priority) }
                    .thenBy { it.createdAt },
            )
            return sortedTasks
        }

        private fun priorityWeight(priority: String): Int {
            return when (priority) {
                "high" -> 3
                "medium" -> 2
                else -> 1
            }
        }

        private fun encodeTasks(tasks: List<TaskRecord>): String {
            val array = JSONArray()
            for (task in tasks) {
                array.put(task.toJson())
            }
            return array.toString()
        }
    }
}
