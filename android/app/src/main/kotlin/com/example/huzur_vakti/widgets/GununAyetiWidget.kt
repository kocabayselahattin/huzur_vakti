package com.example.huzur_vakti.widgets

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import com.example.huzur_vakti.R
import es.antonborri.home_widget.HomeWidgetPlugin

class GununAyetiWidget : AppWidgetProvider() {
    
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
            
            val ayetArapca = widgetData.getString("ayet_arapca", "إِنَّ مَعَ الْعُسْرِ يُسْرًا") 
                ?: "إِنَّ مَعَ الْعُسْرِ يُسْرًا"
            val ayetMeal = widgetData.getString("ayet_meal", "Şüphesiz zorlukla birlikte kolaylık vardır.") 
                ?: "Şüphesiz zorlukla birlikte kolaylık vardır."
            val ayetKaynak = widgetData.getString("ayet_kaynak", "İnşirah Suresi, 6") 
                ?: "İnşirah Suresi, 6"
            
            val views = RemoteViews(context.packageName, R.layout.widget_gunun_ayeti)
            views.setTextViewText(R.id.tv_ayet_arapca, ayetArapca)
            views.setTextViewText(R.id.tv_ayet_meal, ayetMeal)
            views.setTextViewText(R.id.tv_ayet_kaynak, ayetKaynak)
            
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
