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
                    val nextCourseJson = json.optJSONObject("nextCourse")

                    // 设置日期
                    views.setTextViewText(R.id.widget_title, "今日课表")
                    views.setTextViewText(R.id.widget_date, dateLabel)
                    views.setTextViewText(R.id.widget_week, weekLabel)

                    // 处理下一节课
                    if (nextCourseJson != null && nextCourseJson.optInt("minutesUntilStart", -1) >= 0) {
                        val nextName = nextCourseJson.optString("name", "")
                        val nextLocation = nextCourseJson.optString("location", "")
                        val nextStart = nextCourseJson.optInt("startPeriod", 1)
                        val nextEnd = nextCourseJson.optInt("endPeriod", 1)
                        val nextMinutes = nextCourseJson.optInt("minutesUntilStart", 0)
                        val nextStatus = nextCourseJson.optString("status", "")
                        val nextColor = nextCourseJson.optString("colorHex", "#5C6BC0")

                        views.setViewVisibility(R.id.next_course_container, View.VISIBLE)
                        views.setViewVisibility(R.id.widget_empty, View.GONE)
                        views.setViewVisibility(R.id.widget_courses_container, View.VISIBLE)

                        // 设置下一节课颜色
                        try {
                            views.setInt(R.id.next_course_color, "setBackgroundColor", Color.parseColor(nextColor))
                            views.setInt(R.id.next_course_countdown, "setTextColor", Color.parseColor(nextColor))
                        } catch (e: Exception) { }

                        views.setTextViewText(R.id.next_course_status, nextStatus)
                        views.setTextViewText(R.id.next_course_name, nextName)
                        views.setTextViewText(R.id.next_course_info, "${nextStart}-${nextEnd}节" +
                            if (nextLocation.isNotEmpty()) " · $nextLocation" else "")
                        views.setTextViewText(R.id.next_course_countdown, nextMinutes.toString())
                    } else {
                        // 今天没有下一节课了
                        views.setViewVisibility(R.id.next_course_container, View.GONE)
                    }

                    // 处理课程列表
                    if (coursesArray == null || coursesArray.length() == 0) {
                        views.setViewVisibility(R.id.widget_empty, View.VISIBLE)
                        views.setViewVisibility(R.id.widget_courses_container, View.GONE)
                    } else {
                        views.setViewVisibility(R.id.widget_courses_container, View.VISIBLE)

                        val courseRootIds = listOf(R.id.course_1_root, R.id.course_2_root, R.id.course_3_root, R.id.course_4_root)
                        val courseColorIds = listOf(R.id.course_1_color, R.id.course_2_color, R.id.course_3_color, R.id.course_4_color)
                        val courseNameIds = listOf(R.id.course_1_name, R.id.course_2_name, R.id.course_3_name, R.id.course_4_name)
                        val courseInfoIds = listOf(R.id.course_1_info, R.id.course_2_info, R.id.course_3_info, R.id.course_4_info)

                        // 最多显示4门课
                        val maxCourses = minOf(coursesArray.length(), 4)

                        for (i in 0 until 4) {
                            if (i < maxCourses) {
                                val course = coursesArray.getJSONObject(i)
                                val name = course.optString("name", "未知课程")
                                val location = course.optString("location", "")
                                val startPeriod = course.optInt("startPeriod", 1)
                                val endPeriod = course.optInt("endPeriod", 1)
                                val colorHex = course.optString("colorHex", "#5C6BC0")

                                try {
                                    views.setInt(courseColorIds[i], "setBackgroundColor", Color.parseColor(colorHex))
                                } catch (e: Exception) { }

                                views.setTextViewText(courseNameIds[i], name)
                                views.setTextViewText(courseInfoIds[i], "${startPeriod}-${endPeriod}节")
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

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }

        private fun showEmptyState(views: RemoteViews, message: String) {
            views.setTextViewText(R.id.widget_title, "今日课表")
            views.setTextViewText(R.id.widget_date, "")
            views.setTextViewText(R.id.widget_week, "")
            views.setViewVisibility(R.id.next_course_container, View.GONE)
            views.setViewVisibility(R.id.widget_empty, View.VISIBLE)
            views.setViewVisibility(R.id.widget_courses_container, View.GONE)
            views.setTextViewText(R.id.widget_empty, message)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
    }
}