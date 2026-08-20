package com.pulpo.android

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class PulpoBudgetWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        appWidgetIds.forEach { widgetId ->
            val percent = widgetData.getString("budget_percent", "0")?.toIntOrNull() ?: 0
            val views = RemoteViews(context.packageName, R.layout.pulpo_budget_widget).apply {
                setTextViewText(
                    R.id.widget_month,
                    widgetData.getString("month_label", ""),
                )
                setTextViewText(
                    R.id.widget_left_label,
                    widgetData.getString("budget_left_label", "Left"),
                )
                setTextViewText(
                    R.id.widget_budget_left,
                    widgetData.getString("budget_left", "—"),
                )
                setProgressBar(R.id.widget_progress, 100, percent, false)
                setTextViewText(R.id.widget_percent, "$percent%")
                setOnClickPendingIntent(
                    R.id.widget_root,
                    HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java),
                )
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
