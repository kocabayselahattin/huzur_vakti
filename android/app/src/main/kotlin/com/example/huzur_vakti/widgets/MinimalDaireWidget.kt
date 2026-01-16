package com.example.huzur_vakti.widgets

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import com.example.huzur_vakti.R
import es.antonborri.home_widget.HomeWidgetPlugin

class MinimalDaireWidget : AppWidgetProvider() {
    
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
            
            val vakitAdi = widgetData.getString("sonraki_vakit", "AKŞAM") ?: "AKŞAM"
            val vakitSaati = widgetData.getString("sonraki_vakit_saati", "17:45") ?: "17:45"
            val kalanKisa = widgetData.getString("kalan_kisa", "2s 15dk") ?: "2s 15dk"
            
            val views = RemoteViews(context.packageName, R.layout.widget_minimal_daire)
            views.setTextViewText(R.id.tv_vakit_adi, vakitAdi.uppercase())
            views.setTextViewText(R.id.tv_vakit_saati, vakitSaati)
            views.setTextViewText(R.id.tv_kalan, kalanKisa)
            
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
