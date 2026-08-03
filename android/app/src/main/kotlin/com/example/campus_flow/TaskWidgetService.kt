package com.example.campus_flow

import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import android.widget.RemoteViewsService
import androidx.core.content.ContextCompat
import org.json.JSONArray
import org.json.JSONObject

class TaskWidgetService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory {
        return TaskWidgetFactory(applicationContext)
    }
}

internal data class TaskRecord(
    val id: String,
    val title: String,
    val priority: String,
    val createdAt: String,
    val isCompleted: Boolean,
) {
    fun toJson(): JSONObject {
        return JSONObject()
            .put("id", id)
            .put("title", title)
            .put("priority", priority)
            .put("createdAt", createdAt)
            .put("isCompleted", isCompleted)
    }
}

class TaskWidgetFactory(private val context: Context) : RemoteViewsService.RemoteViewsFactory {
    private val tasks = mutableListOf<TaskRecord>()

    override fun onCreate() {
        loadData()
    }

    override fun onDataSetChanged() {
        loadData()
    }

    override fun onDestroy() {
        tasks.clear()
    }

    override fun getCount(): Int = tasks.size

    override fun getViewAt(position: Int): RemoteViews? {
        if (position < 0 || position >= tasks.size) return null

        val task = tasks[position]
        val views = RemoteViews(context.packageName, R.layout.task_widget_item)

        views.setTextViewText(R.id.task_title, task.title)

        val primaryTextColor = ContextCompat.getColor(context, R.color.task_text_primary)
        val completedTextColor = ContextCompat.getColor(context, R.color.task_text_completed)

        if (task.isCompleted) {
            views.setTextColor(R.id.task_title, completedTextColor)
            views.setImageViewResource(R.id.task_checkbox, R.drawable.ic_checkbox_checked)
        } else {
            views.setTextColor(R.id.task_title, primaryTextColor)
            views.setImageViewResource(R.id.task_checkbox, R.drawable.ic_checkbox_unchecked)
        }

        val priorityRes = when (task.priority) {
            "high" -> R.drawable.ic_priority_high
            "medium" -> R.drawable.ic_priority_medium
            else -> R.drawable.ic_priority_low
        }
        views.setImageViewResource(R.id.task_priority_flag, priorityRes)

        val fillInIntent = Intent().apply {
            putExtra(TaskWidgetProvider.EXTRA_TASK_ID, task.id)
        }
        views.setOnClickFillInIntent(R.id.task_item_container, fillInIntent)
        views.setOnClickFillInIntent(R.id.task_checkbox, fillInIntent)

        return views
    }

    override fun getLoadingView(): RemoteViews? = null

    override fun getViewTypeCount(): Int = 1

    override fun getItemId(position: Int): Long = tasks.getOrNull(position)?.id?.hashCode()?.toLong() ?: position.toLong()

    override fun hasStableIds(): Boolean = true

    private fun loadData() {
        tasks.clear()
        val prefs = context.getSharedPreferences(MainActivity.PREFS_NAME, Context.MODE_PRIVATE)
        val encodedTasks = prefs.getString(MainActivity.TASKS_KEY, "[]") ?: "[]"
        val array = JSONArray(encodedTasks)
        val rawTasks = mutableListOf<TaskRecord>()

        for (index in 0 until array.length()) {
            val item = array.getJSONObject(index)
            rawTasks.add(
                TaskRecord(
                    id = item.getString("id"),
                    title = item.getString("title"),
                    priority = item.getString("priority"),
                    createdAt = item.getString("createdAt"),
                    isCompleted = item.optBoolean("isCompleted", false),
                )
            )
        }

        rawTasks.sortWith(
            compareBy<TaskRecord> { it.isCompleted }
                .thenByDescending { priorityWeight(it.priority) }
                .thenBy { it.createdAt }
        )

        tasks.addAll(rawTasks)
    }

    private fun priorityWeight(priority: String): Int {
        return when (priority) {
            "high" -> 3
            "medium" -> 2
            else -> 1
        }
    }
}
