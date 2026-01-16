package com.example.huzur_vakti.widgets

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.widget.RemoteViews
import com.example.huzur_vakti.R
import es.antonborri.home_widget.HomeWidgetPlugin

class CamiSiluetWidget : AppWidgetProvider() {
    
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
            val thisWidget = android.content.ComponentName(context, CamiSiluetWidget::class.java)
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
            val kalanSure = widgetData.getString("kalan_sure", "02:30:45") ?: "02:30:45"
            val miladiTarih = widgetData.getString("miladi_tarih", "1 Ocak 2025") ?: "1 Ocak 2025"
            val konum = widgetData.getString("konum", "İstanbul") ?: "İstanbul"
            
            // Renk ayarlarını al
            val arkaPlanKey = widgetData.getString("arkaplan_key", "dark") ?: "dark"
            val yaziRengiHex = widgetData.getString("yazi_rengi_hex", "FFFFFF") ?: "FFFFFF"
            val yaziRengi = Color.parseColor("#$yaziRengiHex")
            val yaziRengiSecondary = Color.argb(180, Color.red(yaziRengi), Color.green(yaziRengi), Color.blue(yaziRengi))
            
            val views = RemoteViews(context.packageName, R.layout.widget_cami_siluet)
            
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
                else -> R.drawable.widget_bg_dark_mosque
            }
            views.setInt(R.id.widget_root, "setBackgroundResource", bgDrawable)
            
            // Sonraki vakit ve geri sayım
            val sonrakiVakitText = when(sonrakiVakit) {
                "İmsak" -> "İmsak Vaktine"
                "Güneş" -> "Güneş Doğuşuna"
                "Öğle" -> "Öğle Vaktine"
                "İkindi" -> "İkindi Vaktine"
                "Akşam" -> "Akşam Vaktine"
                "Yatsı" -> "Yatsı Vaktine"
                else -> "$sonrakiVakit Vaktine"
            }
            views.setTextViewText(R.id.tv_sonraki_vakit_adi, sonrakiVakitText)
            views.setTextColor(R.id.tv_sonraki_vakit_adi, yaziRengiSecondary)
            
            // Kalan süreyi böl
            val sureParts = kalanSure.split(":")
            if (sureParts.size >= 2) {
                views.setTextViewText(R.id.tv_countdown, "${sureParts[0]}:${sureParts[1]}")
                views.setTextColor(R.id.tv_countdown, yaziRengi)
                if (sureParts.size >= 3) {
                    views.setTextViewText(R.id.tv_countdown_saniye, sureParts[2])
                    views.setTextColor(R.id.tv_countdown_saniye, yaziRengiSecondary)
                }
            } else {
                views.setTextViewText(R.id.tv_countdown, kalanSure)
                views.setTextColor(R.id.tv_countdown, yaziRengi)
            }
            
            // Tarih ve konum
            val gunAdi = java.text.SimpleDateFormat("EEEE", java.util.Locale("tr")).format(java.util.Date())
            views.setTextViewText(R.id.tv_gun, gunAdi)
            views.setTextColor(R.id.tv_gun, yaziRengi)
            views.setTextViewText(R.id.tv_miladi_tarih, miladiTarih)
            views.setTextColor(R.id.tv_miladi_tarih, yaziRengiSecondary)
            
            // Vakit saatlerini ayarla (renk ile)
            views.setTextViewText(R.id.tv_imsak, imsak)
            views.setTextColor(R.id.tv_imsak, yaziRengi)
            views.setTextViewText(R.id.tv_gunes, gunes)
            views.setTextColor(R.id.tv_gunes, yaziRengi)
            views.setTextViewText(R.id.tv_ogle, ogle)
            views.setTextColor(R.id.tv_ogle, yaziRengi)
            views.setTextViewText(R.id.tv_ikindi, ikindi)
            views.setTextColor(R.id.tv_ikindi, yaziRengi)
            views.setTextViewText(R.id.tv_aksam, aksam)
            views.setTextColor(R.id.tv_aksam, yaziRengi)
            views.setTextViewText(R.id.tv_yatsi, yatsi)
            views.setTextColor(R.id.tv_yatsi, yaziRengi)
            
            // Hadis metni (varsayılan bir hadis)
            val hadis = widgetData.getString("gunun_hadisi", 
                "Kim Allah'a ve ahiret gününe iman ediyorsa ya hayır söylesin ya da sussun.") 
                ?: "Kim Allah'a ve ahiret gününe iman ediyorsa ya hayır söylesin ya da sussun."
            views.setTextViewText(R.id.tv_hadis, hadis)
            views.setTextColor(R.id.tv_hadis, yaziRengiSecondary)
            
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
