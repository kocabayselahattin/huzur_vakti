package com.example.huzur_vakti.widgets

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.os.Bundle
import android.util.TypedValue
import android.view.View
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

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle
    ) {
        updateAppWidget(context, appWidgetManager, appWidgetId)
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
            
            // Geri sayımı Android tarafında hesapla (uygulama kapalıyken de çalışır)
            val vakitBilgisi = WidgetUtils.hesaplaVakitBilgisi(imsak, gunes, ogle, ikindi, aksam, yatsi)
            val sonrakiVakit = vakitBilgisi["sonrakiVakit"] ?: "Öğle"
            val geriSayim = vakitBilgisi["geriSayim"] ?: "02:30:00"
            val mevcutVakit = vakitBilgisi["mevcutVakit"] ?: "İmsak"
            
            val hicriTarih = widgetData.getString("hicri_tarih", "1 Muharrem 1447") ?: "1 Muharrem 1447"
            val miladiTarih = widgetData.getString("miladi_tarih", "17 Ocak 2026") ?: "17 Ocak 2026"
            val konum = widgetData.getString("konum", "İstanbul") ?: "İstanbul"

            
            // Renk ayarlarını al
            val arkaPlanKey = widgetData.getString("arkaplan_key", "light") ?: "light"
            val yaziRengiHex = widgetData.getString("yazi_rengi_hex", "444444") ?: "444444"
            val yaziRengi = WidgetUtils.parseColorSafe(yaziRengiHex, Color.parseColor("#444444"))
            val yaziRengiSecondary = Color.argb(180, Color.red(yaziRengi), Color.green(yaziRengi), Color.blue(yaziRengi))
            
            val views = RemoteViews(context.packageName, R.layout.widget_kompakt_banner)


            val options = appWidgetManager.getAppWidgetOptions(appWidgetId)
            val minHeight = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT)
            val isTall = minHeight >= 110

            views.setViewVisibility(R.id.layout_grid, if (isTall) View.VISIBLE else View.GONE)
            views.setViewVisibility(R.id.layout_row, if (isTall) View.GONE else View.VISIBLE)
            
            // Arka plan ayarla
            val bgDrawable = when(arkaPlanKey) {
                "orange" -> R.drawable.widget_bg_orange
                "light" -> R.drawable.widget_bg_card_light
                "dark" -> R.drawable.widget_bg_card_dark
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
                else -> R.drawable.widget_bg_card_dark
            }
            views.setInt(R.id.widget_root, "setBackgroundResource", bgDrawable)
            
            // Konum ve tarih
            val sehir = konum.split("/").firstOrNull()?.trim() ?: konum
            views.setTextViewText(R.id.tv_location_grid, "$sehir, ${konum.split("/").getOrNull(1)?.trim() ?: ""}".trim().trimEnd(','))
            views.setTextViewText(R.id.tv_date_grid, "$miladiTarih • $hicriTarih")
            views.setTextColor(R.id.tv_location_grid, yaziRengi)
            views.setTextColor(R.id.tv_date_grid, yaziRengiSecondary)

            // Başlık ve geri sayım
            views.setTextViewText(R.id.tv_sonraki_label_grid, "$sonrakiVakit Vaktine Kalan")
            views.setTextViewText(R.id.tv_sonraki_adi_grid, sonrakiVakit.uppercase())
            WidgetUtils.applyCountdown(views, R.id.tv_countdown_grid, geriSayim)
            views.setTextColor(R.id.tv_sonraki_label_grid, yaziRengiSecondary)
            views.setTextColor(R.id.tv_sonraki_adi_grid, yaziRengi)
            views.setTextColor(R.id.tv_countdown_grid, yaziRengi)

            views.setTextViewText(R.id.tv_sonraki_label_row, "$sonrakiVakit Vaktine Kalan")
            WidgetUtils.applyCountdown(views, R.id.tv_countdown_row, geriSayim)
            views.setTextColor(R.id.tv_sonraki_label_row, yaziRengiSecondary)
            views.setTextColor(R.id.tv_countdown_row, yaziRengi)
            
            // Vakit saatlerini ayarla (renk ile)
            val imsakColor = if (mevcutVakit == "İmsak") yaziRengi else yaziRengiSecondary
            val gunesColor = if (mevcutVakit == "Güneş") yaziRengi else yaziRengiSecondary
            val ogleColor = if (mevcutVakit == "Öğle") yaziRengi else yaziRengiSecondary
            val ikindiColor = if (mevcutVakit == "İkindi") yaziRengi else yaziRengiSecondary
            val aksamColor = if (mevcutVakit == "Akşam") yaziRengi else yaziRengiSecondary
            val yatsiColor = if (mevcutVakit == "Yatsı") yaziRengi else yaziRengiSecondary

            val activeBox = R.drawable.widget_vakit_active_orange
            val inactiveBox = R.drawable.widget_vakit_inactive_dark

            views.setInt(R.id.box_imsak_grid, "setBackgroundResource", if (mevcutVakit == "İmsak") activeBox else inactiveBox)
            views.setInt(R.id.box_gunes_grid, "setBackgroundResource", if (mevcutVakit == "Güneş") activeBox else inactiveBox)
            views.setInt(R.id.box_ogle_grid, "setBackgroundResource", if (mevcutVakit == "Öğle") activeBox else inactiveBox)
            views.setInt(R.id.box_ikindi_grid, "setBackgroundResource", if (mevcutVakit == "İkindi") activeBox else inactiveBox)
            views.setInt(R.id.box_aksam_grid, "setBackgroundResource", if (mevcutVakit == "Akşam") activeBox else inactiveBox)
            views.setInt(R.id.box_yatsi_grid, "setBackgroundResource", if (mevcutVakit == "Yatsı") activeBox else inactiveBox)

            views.setInt(R.id.box_imsak_row, "setBackgroundResource", if (mevcutVakit == "İmsak") activeBox else inactiveBox)
            views.setInt(R.id.box_gunes_row, "setBackgroundResource", if (mevcutVakit == "Güneş") activeBox else inactiveBox)
            views.setInt(R.id.box_ogle_row, "setBackgroundResource", if (mevcutVakit == "Öğle") activeBox else inactiveBox)
            views.setInt(R.id.box_ikindi_row, "setBackgroundResource", if (mevcutVakit == "İkindi") activeBox else inactiveBox)
            views.setInt(R.id.box_aksam_row, "setBackgroundResource", if (mevcutVakit == "Akşam") activeBox else inactiveBox)
            views.setInt(R.id.box_yatsi_row, "setBackgroundResource", if (mevcutVakit == "Yatsı") activeBox else inactiveBox)

            views.setTextViewText(R.id.tv_imsak_grid, imsak)
            views.setTextColor(R.id.tv_imsak_grid, imsakColor)
            views.setTextViewText(R.id.tv_gunes_grid, gunes)
            views.setTextColor(R.id.tv_gunes_grid, gunesColor)
            views.setTextViewText(R.id.tv_ogle_grid, ogle)
            views.setTextColor(R.id.tv_ogle_grid, ogleColor)
            views.setTextViewText(R.id.tv_ikindi_grid, ikindi)
            views.setTextColor(R.id.tv_ikindi_grid, ikindiColor)
            views.setTextViewText(R.id.tv_aksam_grid, aksam)
            views.setTextColor(R.id.tv_aksam_grid, aksamColor)
            views.setTextViewText(R.id.tv_yatsi_grid, yatsi)
            views.setTextColor(R.id.tv_yatsi_grid, yatsiColor)

            views.setTextViewText(R.id.tv_imsak_row, imsak)
            views.setTextColor(R.id.tv_imsak_row, imsakColor)
            views.setTextViewText(R.id.tv_gunes_row, gunes)
            views.setTextColor(R.id.tv_gunes_row, gunesColor)
            views.setTextViewText(R.id.tv_ogle_row, ogle)
            views.setTextColor(R.id.tv_ogle_row, ogleColor)
            views.setTextViewText(R.id.tv_ikindi_row, ikindi)
            views.setTextColor(R.id.tv_ikindi_row, ikindiColor)
            views.setTextViewText(R.id.tv_aksam_row, aksam)
            views.setTextColor(R.id.tv_aksam_row, aksamColor)
            views.setTextViewText(R.id.tv_yatsi_row, yatsi)
            views.setTextColor(R.id.tv_yatsi_row, yatsiColor)

            views.setOnClickPendingIntent(R.id.widget_root, WidgetUtils.createLaunchPendingIntent(context))
            
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
