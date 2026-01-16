package com.example.huzur_vakti.widgets

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import com.example.huzur_vakti.R
import es.antonborri.home_widget.HomeWidgetPlugin

class ZikirSayacWidget : AppWidgetProvider() {
    
    companion object {
        const val ACTION_INCREMENT = "com.example.huzur_vakti.ACTION_INCREMENT"
        const val ACTION_DECREMENT = "com.example.huzur_vakti.ACTION_DECREMENT"
        
        internal fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val widgetData = HomeWidgetPlugin.getData(context)
            
            val zikirMetin = widgetData.getString("zikir_metin", "سُبْحَانَ اللّهِ") ?: "سُبْحَانَ اللّهِ"
            val zikirAnlam = widgetData.getString("zikir_anlam", "Sübhanallah") ?: "Sübhanallah"
            val zikirSayac = widgetData.getInt("zikir_sayac", 33)
            
            val views = RemoteViews(context.packageName, R.layout.widget_zikir_sayac)
            views.setTextViewText(R.id.tv_zikir_metin, zikirMetin)
            views.setTextViewText(R.id.tv_zikir_anlam, zikirAnlam)
            views.setTextViewText(R.id.tv_zikir_sayac, zikirSayac.toString())
            
            // Artır butonu için PendingIntent
            val incrementIntent = Intent(context, ZikirSayacWidget::class.java).apply {
                action = ACTION_INCREMENT
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
            }
            val incrementPendingIntent = PendingIntent.getBroadcast(
                context, appWidgetId, incrementIntent, 
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.btn_zikir_artir, incrementPendingIntent)
            
            // Azalt butonu için PendingIntent
            val decrementIntent = Intent(context, ZikirSayacWidget::class.java).apply {
                action = ACTION_DECREMENT
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
            }
            val decrementPendingIntent = PendingIntent.getBroadcast(
                context, appWidgetId + 1000, decrementIntent, 
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.btn_zikir_azalt, decrementPendingIntent)
            
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
    
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }
    
    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        
        when (intent.action) {
            ACTION_INCREMENT -> {
                val widgetData = HomeWidgetPlugin.getData(context)
                val currentCount = widgetData.getInt("zikir_sayac", 33)
                widgetData.edit().putInt("zikir_sayac", currentCount + 1).apply()
                
                val appWidgetManager = AppWidgetManager.getInstance(context)
                val appWidgetId = intent.getIntExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, -1)
                if (appWidgetId != -1) {
                    updateAppWidget(context, appWidgetManager, appWidgetId)
                }
            }
            ACTION_DECREMENT -> {
                val widgetData = HomeWidgetPlugin.getData(context)
                val currentCount = widgetData.getInt("zikir_sayac", 33)
                if (currentCount > 0) {
                    widgetData.edit().putInt("zikir_sayac", currentCount - 1).apply()
                }
                
                val appWidgetManager = AppWidgetManager.getInstance(context)
                val appWidgetId = intent.getIntExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, -1)
                if (appWidgetId != -1) {
                    updateAppWidget(context, appWidgetManager, appWidgetId)
                }
            }
        }
    }
}
