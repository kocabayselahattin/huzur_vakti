package com.example.huzur_vakti.widgets

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import com.example.huzur_vakti.R
import es.antonborri.home_widget.HomeWidgetPlugin

class HaftalikVakitWidget : AppWidgetProvider() {
    
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
            
            val views = RemoteViews(context.packageName, R.layout.widget_haftalik_vakit)
            
            // Gün isimleri
            val gunler = arrayOf("Pzt", "Sal", "Çar", "Per", "Cum", "Cmt", "Paz")
            val gunIds = arrayOf(
                R.id.tv_gun_1, R.id.tv_gun_2, R.id.tv_gun_3, R.id.tv_gun_4,
                R.id.tv_gun_5, R.id.tv_gun_6, R.id.tv_gun_7
            )
            val imsakIds = arrayOf(
                R.id.tv_imsak_1, R.id.tv_imsak_2, R.id.tv_imsak_3, R.id.tv_imsak_4,
                R.id.tv_imsak_5, R.id.tv_imsak_6, R.id.tv_imsak_7
            )
            val aksamIds = arrayOf(
                R.id.tv_aksam_1, R.id.tv_aksam_2, R.id.tv_aksam_3, R.id.tv_aksam_4,
                R.id.tv_aksam_5, R.id.tv_aksam_6, R.id.tv_aksam_7
            )
            
            for (i in 0..6) {
                views.setTextViewText(gunIds[i], gunler[i])
                
                val imsakKey = "haftalik_imsak_$i"
                val aksamKey = "haftalik_aksam_$i"
                
                views.setTextViewText(imsakIds[i], widgetData.getString(imsakKey, "--:--") ?: "--:--")
                views.setTextViewText(aksamIds[i], widgetData.getString(aksamKey, "--:--") ?: "--:--")
            }
            
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
