package com.example.huzur_vakti.widgets

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import com.example.huzur_vakti.R
import es.antonborri.home_widget.HomeWidgetPlugin

class EsmaulHusnaWidget : AppWidgetProvider() {
    
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
            
            val arapca = widgetData.getString("esma_arapca", "الرحمن") ?: "الرحمن"
            val turkce = widgetData.getString("esma_turkce", "ER-RAHMÂN") ?: "ER-RAHMÂN"
            val anlam = widgetData.getString("esma_anlam", "Çok merhametli") ?: "Çok merhametli"
            
            val views = RemoteViews(context.packageName, R.layout.widget_esmaul_husna)
            views.setTextViewText(R.id.tv_esma_arapca, arapca)
            views.setTextViewText(R.id.tv_esma_turkce, turkce)
            views.setTextViewText(R.id.tv_esma_anlam, anlam)
            
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
