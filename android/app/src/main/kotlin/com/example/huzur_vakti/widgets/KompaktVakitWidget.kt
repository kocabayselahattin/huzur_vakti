package com.example.huzur_vakti.widgets

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import com.example.huzur_vakti.R
import es.antonborri.home_widget.HomeWidgetPlugin

class KompaktVakitWidget : AppWidgetProvider() {
    
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onEnabled(context: Context) {
        // Widget ilk kez eklendiğinde
    }

    override fun onDisabled(context: Context) {
        // Widget kaldırıldığında
    }
    
    companion object {
        internal fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val widgetData = HomeWidgetPlugin.getData(context)
            
            val vakitAdi = widgetData.getString("sonraki_vakit", "Öğle") ?: "Öğle"
            val vakitSaati = widgetData.getString("sonraki_vakit_saati", "12:34") ?: "12:34"
            val kalanSure = widgetData.getString("kalan_sure", "2s 15dk kaldı") ?: "2s 15dk kaldı"
            
            val views = RemoteViews(context.packageName, R.layout.widget_kompakt_vakit)
            views.setTextViewText(R.id.tv_vakit_adi, vakitAdi.uppercase())
            views.setTextViewText(R.id.tv_vakit_saati, vakitSaati)
            views.setTextViewText(R.id.tv_kalan_sure, kalanSure)
            
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
