package com.classplan.class_plan

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import android.app.PendingIntent
import android.content.Intent
import android.view.View
import android.os.Build
import java.text.SimpleDateFormat
import java.util.*

class ScheduleWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    companion object {
        private const val ACTION_REFRESH = "com.classplan.class_plan.REFRESH_WIDGET"

        internal fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val views = RemoteViews(context.packageName, R.layout.widget_schedule)

            // Set date
            val now = Calendar.getInstance()
            val dayOfWeek = now.get(Calendar.DAY_OF_WEEK)
            val adjustedDay = if (dayOfWeek == Calendar.SUNDAY) 7 else dayOfWeek - 1
            val dayNames = arrayOf("周日", "周一", "周二", "周三", "周四", "周五", "周六")
            val dateFormat = SimpleDateFormat("M月d日", Locale.CHINA)
            val dateStr = "${dayNames[adjustedDay]} ${dateFormat.format(now.time)}"

            views.setTextViewText(R.id.widget_date, dateStr)
            views.setTextViewText(R.id.widget_title, "今日课表")

            // Hide empty state by default, show courses
            views.setViewVisibility(R.id.widget_empty, View.VISIBLE)

            // Launch app when clicking the widget
            val intent = Intent(context, MainActivity::class.java)
            val pendingIntent = PendingIntent.getActivity(
                context,
                0,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_title, pendingIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action == ACTION_REFRESH) {
            // Refresh handled by Flutter side writing to SharedPreferences
            // and triggering widget update
        }
    }
}
