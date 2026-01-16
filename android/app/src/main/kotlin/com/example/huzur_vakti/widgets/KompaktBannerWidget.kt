package com.example.huzur_vakti.widgets

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.widget.RemoteViews
import com.example.huzur_vakti.R
import es.antonborri.home_widget.HomeWidgetPlugin

class KompaktBannerWidget : AppWidgetProvider() {
    
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
            val thisWidget = android.content.ComponentName(context, KompaktBannerWidget::class.java)
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
            
            // Vakit saatlerini al
            val imsak = widgetData.getString("imsak_saati", "05:30") ?: "05:30"
            val gunes = widgetData.getString("gunes_saati", "07:00") ?: "07:00"
            val ogle = widgetData.getString("ogle_saati", "12:30") ?: "12:30"
            val ikindi = widgetData.getString("ikindi_saati", "15:30") ?: "15:30"
            val aksam = widgetData.getString("aksam_saati", "18:00") ?: "18:00"
            val yatsi = widgetData.getString("yatsi_saati", "19:30") ?: "19:30"
            
            // Diğer bilgiler
            val sonrakiVakit = widgetData.getString("sonraki_vakit", "Öğle") ?: "Öğle"
            val kalanKisa = widgetData.getString("kalan_kisa", "2s 30dk") ?: "2s 30dk"
            val hicriTarih = widgetData.getString("hicri_tarih", "1 Muharrem 1447") ?: "1 Muharrem 1447"
            val konum = widgetData.getString("konum", "İstanbul") ?: "İstanbul"
            
            // Renk ayarlarını al
            val arkaPlanKey = widgetData.getString("arkaplan_key", "light") ?: "light"
            val yaziRengiHex = widgetData.getString("yazi_rengi_hex", "444444") ?: "444444"
            val yaziRengi = Color.parseColor("#$yaziRengiHex")
            val yaziRengiSecondary = Color.argb(180, Color.red(yaziRengi), Color.green(yaziRengi), Color.blue(yaziRengi))
            
            val views = RemoteViews(context.packageName, R.layout.widget_kompakt_banner)
            
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
                else -> R.drawable.widget_bg_light
            }
            views.setInt(R.id.widget_root, "setBackgroundResource", bgDrawable)
            
            // Şehir adını ayarla (renk ile)
            val sehir = konum.split("/").firstOrNull()?.trim() ?: konum
            views.setTextViewText(R.id.tv_sehir, sehir)
            views.setTextColor(R.id.tv_sehir, yaziRengi)
            
            // Hicri tarih
            views.setTextViewText(R.id.tv_hicri, hicriTarih)
            views.setTextColor(R.id.tv_hicri, yaziRengiSecondary)
            
            // Geri sayım
            val sonrakiVakitKisa = when(sonrakiVakit) {
                "İmsak" -> "Sabaha"
                "Güneş" -> "Güneşe"
                "Öğle" -> "Öğleye"
                "İkindi" -> "İkindiye"
                "Akşam" -> "Akşama"
                "Yatsı" -> "Yatsıya"
                else -> "$sonrakiVakit'e"
            }
            views.setTextViewText(R.id.tv_sonraki_vakit_label, "$sonrakiVakitKisa :")
            views.setTextColor(R.id.tv_sonraki_vakit_label, yaziRengiSecondary)
            views.setTextViewText(R.id.tv_countdown, kalanKisa)
            views.setTextColor(R.id.tv_countdown, yaziRengi)
            
            // Vakit saatlerini ayarla (renk ile)
            views.setTextViewText(R.id.tv_imsak, imsak)
            views.setTextColor(R.id.tv_imsak, yaziRengi)
            views.setTextViewText(R.id.tv_gunes, gunes)
            views.setTextColor(R.id.tv_gunes, yaziRengi)
            views.setTextViewText(R.id.tv_gunes2, gunes)
            views.setTextColor(R.id.tv_gunes2, yaziRengi)
            views.setTextViewText(R.id.tv_ogle, ogle)
            views.setTextColor(R.id.tv_ogle, yaziRengi)
            views.setTextViewText(R.id.tv_ikindi, ikindi)
            views.setTextColor(R.id.tv_ikindi, yaziRengi)
            views.setTextViewText(R.id.tv_aksam, aksam)
            views.setTextColor(R.id.tv_aksam, yaziRengi)
            views.setTextViewText(R.id.tv_yatsi, yatsi)
            views.setTextColor(R.id.tv_yatsi, yaziRengi)
            
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
