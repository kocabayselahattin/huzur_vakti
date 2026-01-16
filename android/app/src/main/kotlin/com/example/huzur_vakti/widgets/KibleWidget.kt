package com.example.huzur_vakti.widgets

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import com.example.huzur_vakti.R
import es.antonborri.home_widget.HomeWidgetPlugin

class KibleWidget : AppWidgetProvider() {
    
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
        internal fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val widgetData = HomeWidgetPlugin.getData(context)
            
            val kibleDerece = widgetData.getFloat("kible_derece", 156.7f)
            
            val views = RemoteViews(context.packageName, R.layout.widget_kible)
            views.setTextViewText(R.id.tv_kible_derece, String.format("%.1f°", kibleDerece))
            // Pusula rotasyonunu ayarla (ImageView rotasyonu RemoteViews'da sınırlı)
            
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
