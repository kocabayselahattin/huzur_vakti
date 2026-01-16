package com.example.huzur_vakti.widgets

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import com.example.huzur_vakti.R
import es.antonborri.home_widget.HomeWidgetPlugin

class GunlukVakitlerWidget : AppWidgetProvider() {
    
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
            
            val tarih = widgetData.getString("tarih", "17 Ocak 2026") ?: "17 Ocak 2026"
            val konum = widgetData.getString("konum", "İstanbul") ?: "İstanbul"
            
            val imsak = widgetData.getString("imsak_saati", "05:32") ?: "05:32"
            val gunes = widgetData.getString("gunes_saati", "07:15") ?: "07:15"
            val ogle = widgetData.getString("ogle_saati", "12:34") ?: "12:34"
            val ikindi = widgetData.getString("ikindi_saati", "15:22") ?: "15:22"
            val aksam = widgetData.getString("aksam_saati", "17:45") ?: "17:45"
            val yatsi = widgetData.getString("yatsi_saati", "19:15") ?: "19:15"
            
            val mevcutVakit = widgetData.getString("mevcut_vakit", "Öğle") ?: "Öğle"
            
            val views = RemoteViews(context.packageName, R.layout.widget_gunluk_vakitler)
            views.setTextViewText(R.id.tv_tarih, tarih)
            views.setTextViewText(R.id.tv_konum, "📍 $konum")
            
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
