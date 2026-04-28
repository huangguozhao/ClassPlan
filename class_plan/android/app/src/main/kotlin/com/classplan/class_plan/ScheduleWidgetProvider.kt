package com.classplan.class_plan

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.view.View
import android.widget.RemoteViews
import android.app.PendingIntent
import org.json.JSONObject
import org.json.JSONArray

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
        private const val PREFS_NAME = "FlutterSharedPreferences"
        private const val WIDGET_DATA_KEY = "flutter.widget_schedule_data"

        internal fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val views = RemoteViews(context.packageName, R.layout.widget_schedule)

            // 读取小组件数据
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val jsonStr = prefs.getString(WIDGET_DATA_KEY, null)

            if (jsonStr.isNullOrEmpty()) {
                showEmptyState(views, "请先设置学期\n并导入课表")
            } else {
                try {
                    val json = JSONObject(jsonStr)
                    val dateLabel = json.optString("dateLabel", "")
                    val weekLabel = json.optString("weekLabel", "")
                    val coursesArray = json.optJSONArray("courses")

                    views.setTextViewText(R.id.widget_title, "今日课表")
                    views.setTextViewText(R.id.widget_date, "$dateLabel $weekLabel")

                    if (coursesArray == null || coursesArray.length() == 0) {
                        showEmptyState(views, "今日无课")
                    } else {
                        views.setViewVisibility(R.id.widget_empty, View.GONE)
                        views.setViewVisibility(R.id.widget_courses_container, View.VISIBLE)

                        // 课程视图ID映射
                        val courseRootIds = listOf(R.id.course_1_root, R.id.course_2_root, R.id.course_3_root, R.id.course_4_root)
                        val courseColorIds = listOf(R.id.course_1_color, R.id.course_2_color, R.id.course_3_color, R.id.course_4_color)
                        val courseNameIds = listOf(R.id.course_1_name, R.id.course_2_name, R.id.course_3_name, R.id.course_4_name)
                        val courseInfoIds = listOf(R.id.course_1_info, R.id.course_2_info, R.id.course_3_info, R.id.course_4_info)

                        val maxCourses = minOf(coursesArray.length(), 4)

                        for (i in 0 until 4) {
                            if (i < maxCourses) {
                                val course = coursesArray.getJSONObject(i)
                                val name = course.optString("name", "未知课程")
                                val location = course.optString("location", "")
                                val startPeriod = course.optInt("startPeriod", 1)
                                val endPeriod = course.optInt("endPeriod", 1)
                                val colorHex = course.optString("colorHex", "#5C6BC0")

                                // 设置颜色条
                                try {
                                    val color = Color.parseColor(colorHex)
                                    views.setInt(courseColorIds[i], "setBackgroundColor", color)
                                } catch (e: Exception) { }

                                // 设置课程名
                                views.setTextViewText(courseNameIds[i], name)

                                // 设置课程信息
                                val info = "${startPeriod}-${endPeriod}节" +
                                    if (location.isNotEmpty()) " · $location" else ""
                                views.setTextViewText(courseInfoIds[i], info)

                                views.setViewVisibility(courseRootIds[i], View.VISIBLE)
                            } else {
                                views.setViewVisibility(courseRootIds[i], View.GONE)
                            }
                        }
                    }
                } catch (e: Exception) {
                    showEmptyState(views, "数据解析失败\n请重新打开 App")
                }
            }

            // 点击整个小组件打开 App
            val intent = Intent(context, MainActivity::class.java)
            val pendingIntent = PendingIntent.getActivity(
                context,
                0,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)

            // 刷新按钮 - 启动 Flutter App 触发数据更新
            val refreshIntent = Intent(context, MainActivity::class.java).apply {
                action = "com.classplan.class_plan.REFRESH_WIDGET"
            }
            val refreshPendingIntent = PendingIntent.getActivity(
                context,
                1,
                refreshIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_refresh, refreshPendingIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }

        private fun showEmptyState(views: RemoteViews, message: String) {
            views.setTextViewText(R.id.widget_title, "今日课表")
            views.setTextViewText(R.id.widget_date, "")
            views.setViewVisibility(R.id.widget_empty, View.VISIBLE)
            views.setViewVisibility(R.id.widget_courses_container, View.GONE)
            views.setTextViewText(R.id.widget_empty, message)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        // 处理刷新广播
    }
}