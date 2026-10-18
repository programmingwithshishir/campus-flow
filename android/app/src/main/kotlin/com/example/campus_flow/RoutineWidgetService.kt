package com.example.campus_flow

import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.text.SpannableString
import android.text.Spanned
import android.text.style.StrikethroughSpan
import android.widget.RemoteViews
import android.widget.RemoteViewsService
import androidx.core.content.ContextCompat
import org.json.JSONArray
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Locale

class RoutineWidgetService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory {
        return RoutineWidgetFactory(applicationContext)
    }
}

internal data class RoutineRecord(
    val id: String,
    val name: String,
    val hour: Int,
    val minute: Int,
    val days: List<Int>,
    val isEnabled: Boolean,
    val createdAt: String,
    val lastCompletedDate: String?,
) {
    fun isCompleted(todayStr: String): Boolean {
        return lastCompletedDate != null && lastCompletedDate == todayStr
    }

    fun formattedTime(): String {
        val period = if (hour >= 12) "PM" else "AM"
        val displayHour = if (hour == 0) 12 else if (hour > 12) hour - 12 else hour
        val displayMinute = String.format(Locale.US, "%02d", minute)
        return "$displayHour:$displayMinute $period"
    }

    fun toJson(): JSONObject {
        val obj = JSONObject()
            .put("id", id)
            .put("name", name)
            .put("hour", hour)
            .put("minute", minute)
            .put("days", JSONArray(days))
            .put("isEnabled", isEnabled)
            .put("createdAt", createdAt)
        if (lastCompletedDate != null) {
            obj.put("lastCompletedDate", lastCompletedDate)
        } else {
            obj.put("lastCompletedDate", JSONObject.NULL)
        }
        return obj
    }
}

class RoutineWidgetFactory(private val context: Context) : RemoteViewsService.RemoteViewsFactory {
    private val routines = mutableListOf<RoutineRecord>()
    private var todayStr = ""

    override fun onCreate() {
        loadData()
    }

    override fun onDataSetChanged() {
        loadData()
    }

    override fun onDestroy() {
        routines.clear()
    }

    override fun getCount(): Int = routines.size

    override fun getViewAt(position: Int): RemoteViews? {
        if (position < 0 || position >= routines.size) return null

        val routine = routines[position]
        val views = RemoteViews(context.packageName, R.layout.routine_widget_item)

        val primaryTextColor = ContextCompat.getColor(context, R.color.task_text_primary)
        val completedTextColor = ContextCompat.getColor(context, R.color.task_text_completed)

        val isCompletedToday = routine.isCompleted(todayStr)

        if (isCompletedToday) {
            val spannable = SpannableString(routine.name).apply {
                setSpan(StrikethroughSpan(), 0, length, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)
            }
            views.setTextViewText(R.id.routine_title, spannable)
            views.setTextColor(R.id.routine_title, completedTextColor)
            views.setImageViewResource(R.id.routine_checkbox, R.drawable.ic_checkbox_checked)
        } else {
            views.setTextViewText(R.id.routine_title, routine.name)
            views.setTextColor(R.id.routine_title, primaryTextColor)
            views.setImageViewResource(R.id.routine_checkbox, R.drawable.ic_checkbox_unchecked)
        }

        views.setTextViewText(R.id.routine_time, routine.formattedTime())

        // Open app when clicking container, title, or time
        val openAppIntent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val openAppPendingIntent = PendingIntent.getActivity(
            context,
            2,
            openAppIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.routine_item_container, openAppPendingIntent)
        views.setOnClickPendingIntent(R.id.routine_title, openAppPendingIntent)
        views.setOnClickPendingIntent(R.id.routine_time, openAppPendingIntent)

        // Toggle routine completion ONLY when clicking the checkbox icon
        val fillInIntent = Intent().apply {
            putExtra(RoutineWidgetProvider.EXTRA_ROUTINE_ID, routine.id)
        }
        views.setOnClickFillInIntent(R.id.routine_checkbox, fillInIntent)

        return views
    }

    override fun getLoadingView(): RemoteViews? = null

    override fun getViewTypeCount(): Int = 1

    override fun getItemId(position: Int): Long = routines.getOrNull(position)?.id?.hashCode()?.toLong() ?: position.toLong()

    override fun hasStableIds(): Boolean = true

    private fun loadData() {
        routines.clear()

        val calendar = Calendar.getInstance()
        todayStr = SimpleDateFormat("yyyy-MM-dd", Locale.US).format(calendar.time)

        val dartWeekday = when (calendar.get(Calendar.DAY_OF_WEEK)) {
            Calendar.MONDAY -> 1
            Calendar.TUESDAY -> 2
            Calendar.WEDNESDAY -> 3
            Calendar.THURSDAY -> 4
            Calendar.FRIDAY -> 5
            Calendar.SATURDAY -> 6
            Calendar.SUNDAY -> 7
            else -> 1
        }

        val prefs = context.getSharedPreferences(MainActivity.PREFS_NAME, Context.MODE_PRIVATE)
        val encodedRoutines = prefs.getString(MainActivity.ROUTINES_KEY, "[]") ?: "[]"
        val array = JSONArray(encodedRoutines)
        val filteredRoutines = mutableListOf<RoutineRecord>()

        for (index in 0 until array.length()) {
            val item = array.getJSONObject(index)
            val daysArray = item.optJSONArray("days") ?: JSONArray()
            val daysList = mutableListOf<Int>()
            for (d in 0 until daysArray.length()) {
                daysList.add(daysArray.getInt(d))
            }

            // Only include routines scheduled for today
            if (daysList.contains(dartWeekday)) {
                val lastCompleted = if (item.isNull("lastCompletedDate")) null else item.optString("lastCompletedDate")
                filteredRoutines.add(
                    RoutineRecord(
                        id = item.optString("id"),
                        name = item.optString("name"),
                        hour = item.optInt("hour", 0),
                        minute = item.optInt("minute", 0),
                        days = daysList,
                        isEnabled = item.optBoolean("isEnabled", true),
                        createdAt = item.optString("createdAt", ""),
                        lastCompletedDate = if (lastCompleted.isNullOrEmpty()) null else lastCompleted,
                    )
                )
            }
        }

        // Sort: incomplete first, then by time (hour * 60 + minute), then createdAt
        filteredRoutines.sortWith(
            compareBy<RoutineRecord> { it.isCompleted(todayStr) }
                .thenBy { (it.hour * 60) + it.minute }
                .thenBy { it.createdAt }
        )

        routines.addAll(filteredRoutines)
    }
}
