package com.pulpo.android

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class PulpoChartWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val barIds = intArrayOf(
            R.id.bar1, R.id.bar2, R.id.bar3, R.id.bar4,
            R.id.bar5, R.id.bar6, R.id.bar7,
        )
        val bars = widgetData.getString("daily_bars", "")
            ?.split(",")
            ?.mapNotNull { it.trim().toIntOrNull() }
            ?: emptyList()

        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.pulpo_chart_widget).apply {
                setTextViewText(
                    R.id.widget_month,
                    widgetData.getString("month_label", ""),
                )
                setTextViewText(
                    R.id.widget_expense_label,
                    widgetData.getString("expense_label", "Expense"),
                )
                setTextViewText(
                    R.id.widget_spent,
                    widgetData.getString("spent", "—"),
                )
                for (i in barIds.indices) {
                    val value = bars.getOrNull(i) ?: 0
                    setProgressBar(barIds[i], 100, value, false)
                }
                setOnClickPendingIntent(
                    R.id.widget_root,
                    HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java),
                )
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
