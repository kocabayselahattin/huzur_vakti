package com.example.huzur_vakti.widgets

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import com.example.huzur_vakti.R
import es.antonborri.home_widget.HomeWidgetPlugin

class GununSozuWidget : AppWidgetProvider() {
    
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
            
            val sozIcerik = widgetData.getString("gunun_sozu", "İyiliğe karşılık iyilik yapın...") 
                ?: "İyiliğe karşılık iyilik yapın..."
            val sozKaynak = widgetData.getString("soz_kaynak", "Buhârî") ?: "Buhârî"
            
            val views = RemoteViews(context.packageName, R.layout.widget_gunun_sozu)
            views.setTextViewText(R.id.tv_soz_icerik, "\"$sozIcerik\"")
            views.setTextViewText(R.id.tv_soz_kaynak, "- $sozKaynak")
            
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
