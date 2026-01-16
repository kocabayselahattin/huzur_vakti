package com.example.huzur_vakti.widgets

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import com.example.huzur_vakti.R
import es.antonborri.home_widget.HomeWidgetPlugin

class IkiVakitWidget : AppWidgetProvider() {
    
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
            
            val mevcutVakit = widgetData.getString("mevcut_vakit", "ÖĞLE") ?: "ÖĞLE"
            val mevcutSaat = widgetData.getString("mevcut_vakit_saati", "12:34") ?: "12:34"
            val sonrakiVakit = widgetData.getString("sonraki_vakit", "İKİNDİ") ?: "İKİNDİ"
            val sonrakiSaat = widgetData.getString("sonraki_vakit_saati", "15:22") ?: "15:22"
            val kalanSure = widgetData.getString("kalan_sure", "2s 45dk kaldı") ?: "2s 45dk kaldı"
            
            val views = RemoteViews(context.packageName, R.layout.widget_sonraki_iki_vakit)
            views.setTextViewText(R.id.tv_mevcut_vakit, mevcutVakit.uppercase())
            views.setTextViewText(R.id.tv_mevcut_saat, mevcutSaat)
            views.setTextViewText(R.id.tv_mevcut_kalan, "Şu an")
            views.setTextViewText(R.id.tv_sonraki_vakit, sonrakiVakit.uppercase())
            views.setTextViewText(R.id.tv_sonraki_saat, sonrakiSaat)
            views.setTextViewText(R.id.tv_sonraki_kalan, kalanSure)
            
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
