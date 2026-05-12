package com.example.markd

import android.appwidget.AppWidgetManager
import android.content.Context
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class TodoinkPinnedWidgetProvider : HomeWidgetProvider() {
  override fun onUpdate(
    context: Context,
    appWidgetManager: AppWidgetManager,
    appWidgetIds: IntArray,
    widgetData: android.content.SharedPreferences,
  ) {
    val pinned1 = widgetData.getString("pinned_1", "") ?: ""
    val pinned2 = widgetData.getString("pinned_2", "") ?: ""
    val pinned3 = widgetData.getString("pinned_3", "") ?: ""

    val anyPinned = pinned1.isNotBlank() || pinned2.isNotBlank() || pinned3.isNotBlank()

    for (widgetId in appWidgetIds) {
      val views = RemoteViews(context.packageName, R.layout.todoink_pinned_widget)

      // Tap widget to open the app.
      val pendingIntent = HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java)
      views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)

      if (!anyPinned) {
        views.setViewVisibility(R.id.widget_empty, android.view.View.VISIBLE)
        views.setViewVisibility(R.id.widget_pinned_1, android.view.View.GONE)
        views.setViewVisibility(R.id.widget_pinned_2, android.view.View.GONE)
        views.setViewVisibility(R.id.widget_pinned_3, android.view.View.GONE)
      } else {
        views.setViewVisibility(R.id.widget_empty, android.view.View.GONE)

        views.setViewVisibility(
          R.id.widget_pinned_1,
          if (pinned1.isNotBlank()) android.view.View.VISIBLE else android.view.View.GONE,
        )
        views.setViewVisibility(
          R.id.widget_pinned_2,
          if (pinned2.isNotBlank()) android.view.View.VISIBLE else android.view.View.GONE,
        )
        views.setViewVisibility(
          R.id.widget_pinned_3,
          if (pinned3.isNotBlank()) android.view.View.VISIBLE else android.view.View.GONE,
        )

        views.setTextViewText(R.id.widget_pinned_1, "• $pinned1")
        views.setTextViewText(R.id.widget_pinned_2, "• $pinned2")
        views.setTextViewText(R.id.widget_pinned_3, "• $pinned3")
      }

      appWidgetManager.updateAppWidget(widgetId, views)
    }
  }
}
