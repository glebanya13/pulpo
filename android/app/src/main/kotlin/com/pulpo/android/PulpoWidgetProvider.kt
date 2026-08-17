package com.pulpo.android

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class PulpoWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.pulpo_widget).apply {
                setTextViewText(
                    R.id.widget_balance_label,
                    widgetData.getString("balance_label", context.getString(R.string.widget_balance)),
                )
                setTextViewText(
                    R.id.widget_balance,
                    widgetData.getString("balance", "—"),
                )
                setTextViewText(
                    R.id.widget_spent_label,
                    widgetData.getString("spent_label", context.getString(R.string.widget_spent)),
                )
                setTextViewText(
                    R.id.widget_spent,
                    widgetData.getString("spent", "—"),
                )
                val pending = HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java)
                setOnClickPendingIntent(R.id.widget_root, pending)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
