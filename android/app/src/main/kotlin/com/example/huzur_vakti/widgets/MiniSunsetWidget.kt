package com.example.huzur_vakti.widgets

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.widget.RemoteViews
import com.example.huzur_vakti.R
import es.antonborri.home_widget.HomeWidgetPlugin

class MiniSunsetWidget : AppWidgetProvider() {
    
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
        if (intent.action == AppWidgetManager.ACTION_APPWIDGET_UPDATE ||
            intent.action == "com.example.huzur_vakti.UPDATE_WIDGETS") {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val thisWidget = android.content.ComponentName(context, MiniSunsetWidget::class.java)
            val appWidgetIds = appWidgetManager.getAppWidgetIds(thisWidget)
            onUpdate(context, appWidgetManager, appWidgetIds)
        }
    }
    
    companion object {
        internal fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val widgetData = HomeWidgetPlugin.getData(context)
            
            // Tüm vakit saatlerini al
            val imsak = widgetData.getString("imsak_saati", "05:30") ?: "05:30"
            val gunes = widgetData.getString("gunes_saati", "07:00") ?: "07:00"
            val ogle = widgetData.getString("ogle_saati", "12:30") ?: "12:30"
            val ikindi = widgetData.getString("ikindi_saati", "15:30") ?: "15:30"
            val aksam = widgetData.getString("aksam_saati", "18:00") ?: "18:00"
            val yatsi = widgetData.getString("yatsi_saati", "19:30") ?: "19:30"
            
            // Diğer bilgiler
            val sonrakiVakit = widgetData.getString("sonraki_vakit", "Öğle") ?: "Öğle"
            val kalanKisa = widgetData.getString("kalan_kisa", "2s 30dk") ?: "2s 30dk"
            
            // Renk ayarlarını al
            val arkaPlanKey = widgetData.getString("arkaplan_key", "sunset") ?: "sunset"
            val yaziRengiHex = widgetData.getString("yazi_rengi_hex", "664422") ?: "664422"
            val yaziRengi = Color.parseColor("#$yaziRengiHex")
            val yaziRengiSecondary = Color.argb(180, Color.red(yaziRengi), Color.green(yaziRengi), Color.blue(yaziRengi))
            
            val views = RemoteViews(context.packageName, R.layout.widget_mini_sunset)
            
            // Arka plan ayarla
            val bgDrawable = when(arkaPlanKey) {
                "orange" -> R.drawable.widget_bg_orange
                "light" -> R.drawable.widget_bg_light
                "dark" -> R.drawable.widget_bg_dark_mosque
                "sunset" -> R.drawable.widget_bg_sunset
                "green" -> R.drawable.widget_bg_green
                "purple" -> R.drawable.widget_bg_purple
                "red" -> R.drawable.widget_bg_red
                "blue" -> R.drawable.widget_bg_blue
                "teal" -> R.drawable.widget_bg_teal
                "pink" -> R.drawable.widget_bg_pink
                "transparent" -> R.drawable.widget_bg_transparent
                "semi_black" -> R.drawable.widget_bg_semi_black
                "semi_white" -> R.drawable.widget_bg_semi_white
                else -> R.drawable.widget_bg_sunset
            }
            views.setInt(R.id.widget_root, "setBackgroundResource", bgDrawable)
            
            // Mevcut saat
            val currentTime = java.text.SimpleDateFormat("HH:mm", java.util.Locale.getDefault()).format(java.util.Date())
            views.setTextViewText(R.id.tv_saat, currentTime)
            views.setTextColor(R.id.tv_saat, yaziRengi)
            
            // Sonraki vakit için saat bul ve bir sonrakini de bul
            val vakitler = listOf(
                "İmsak" to imsak,
                "Güneş" to gunes,
                "Öğle" to ogle,
                "İkindi" to ikindi,
                "Akşam" to aksam,
                "Yatsı" to yatsi
            )
            
            // Sonraki vakti ve ardından geleni bul
            var sonrakiIndex = vakitler.indexOfFirst { it.first == sonrakiVakit }
            if (sonrakiIndex == -1) sonrakiIndex = 0
            
            val sonrakiBirinci = vakitler[sonrakiIndex]
            val sonrakiIkinci = vakitler[(sonrakiIndex + 1) % vakitler.size]
            
            // İlk sonraki vakit (büyük)
            views.setTextViewText(R.id.tv_vakit1_adi, sonrakiBirinci.first)
            views.setTextColor(R.id.tv_vakit1_adi, yaziRengiSecondary)
            views.setTextViewText(R.id.tv_vakit1_saat, sonrakiBirinci.second)
            views.setTextColor(R.id.tv_vakit1_saat, yaziRengi)
            
            // İkinci sonraki vakit
            views.setTextViewText(R.id.tv_vakit2_adi, sonrakiIkinci.first)
            views.setTextColor(R.id.tv_vakit2_adi, yaziRengiSecondary)
            views.setTextViewText(R.id.tv_vakit2_saat, sonrakiIkinci.second)
            views.setTextColor(R.id.tv_vakit2_saat, yaziRengi)
            
            // Geri sayım
            views.setTextViewText(R.id.tv_countdown, kalanKisa)
            views.setTextColor(R.id.tv_countdown, yaziRengi)
            
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
