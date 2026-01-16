package com.example.huzur_vakti.widgets

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import com.example.huzur_vakti.R
import es.antonborri.home_widget.HomeWidgetPlugin

class RamazanSayacWidget : AppWidgetProvider() {
    
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
            
            val ramazanBaslik = widgetData.getString("ramazan_baslik", "İFTARA") ?: "İFTARA"
            val ramazanSayac = widgetData.getString("ramazan_sayac", "04:32:15") ?: "04:32:15"
            val ramazanGun = widgetData.getString("ramazan_gun", "15. Gün") ?: "15. Gün"
            val ramazanKalan = widgetData.getString("ramazan_kalan", "15 gün kaldı") ?: "15 gün kaldı"
            
            val views = RemoteViews(context.packageName, R.layout.widget_ramazan_sayac)
            views.setTextViewText(R.id.tv_ramazan_baslik, ramazanBaslik)
            views.setTextViewText(R.id.tv_ramazan_sayac, ramazanSayac)
            views.setTextViewText(R.id.tv_ramazan_gun, ramazanGun)
            views.setTextViewText(R.id.tv_ramazan_kalan, ramazanKalan)
            
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
