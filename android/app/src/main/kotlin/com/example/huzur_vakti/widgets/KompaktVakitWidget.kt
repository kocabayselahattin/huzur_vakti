package com.example.huzur_vakti.widgets

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.os.Bundle
import android.util.TypedValue
import android.widget.RemoteViews
import com.example.huzur_vakti.R
import es.antonborri.home_widget.HomeWidgetPlugin

class KompaktVakitWidget : AppWidgetProvider() {
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
            val thisWidget = android.content.ComponentName(context, KompaktVakitWidget::class.java)
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
            
            val konum = widgetData.getString("konum", "İstanbul") ?: "İstanbul"
            val miladiTarih = widgetData.getString("miladi_tarih", "17 Ocak 2026") ?: "17 Ocak 2026"
            val hicriTarih = widgetData.getString("hicri_tarih", "28 Recep 1447") ?: "28 Recep 1447"
            val arkaPlanKey = widgetData.getString("arkaplan_key", "light") ?: "light"
            val yaziRengiHex = widgetData.getString("yazi_rengi_hex", "444444") ?: "444444"
            val yaziRengi = WidgetUtils.parseColorSafe(yaziRengiHex, Color.parseColor("#444444"))
            val yaziRengiSecondary = Color.argb(180, Color.red(yaziRengi), Color.green(yaziRengi), Color.blue(yaziRengi))


            val views = RemoteViews(context.packageName, R.layout.widget_kompakt_vakit)


            val options = appWidgetManager.getAppWidgetOptions(appWidgetId)
            val minWidth = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH)

            if (minWidth < 220) {
                views.setTextViewTextSize(R.id.text_geri_sayim, TypedValue.COMPLEX_UNIT_SP, 18f)
            } else {
                views.setTextViewTextSize(R.id.text_geri_sayim, TypedValue.COMPLEX_UNIT_SP, 22f)
            }

            val bgDrawable = when (arkaPlanKey) {
                "orange" -> R.drawable.widget_bg_orange
                "light" -> R.drawable.widget_bg_card_light
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
                else -> R.drawable.widget_bg_card_light
            }
            views.setInt(R.id.widget_root, "setBackgroundResource", bgDrawable)

            WidgetUtils.applyCountdown(views, R.id.text_geri_sayim, geriSayim)
            views.setTextViewText(R.id.text_sonraki_vakit, "$sonrakiVakit Vaktine Kalan")
            views.setTextViewText(R.id.text_konum, konum)
            views.setTextViewText(R.id.tv_date_light, miladiTarih)
            views.setTextViewText(R.id.tv_hicri_light, hicriTarih)

            views.setTextColor(R.id.text_geri_sayim, yaziRengi)
            views.setTextColor(R.id.text_sonraki_vakit, yaziRengiSecondary)
            views.setTextColor(R.id.text_konum, yaziRengi)
            views.setTextColor(R.id.tv_date_light, yaziRengiSecondary)
            views.setTextColor(R.id.tv_hicri_light, yaziRengiSecondary)

            val activeBox = R.drawable.widget_vakit_active_light
            val inactiveBox = R.drawable.widget_vakit_inactive_light

            views.setInt(R.id.box_imsak_light, "setBackgroundResource", if (mevcutVakit == "İmsak") activeBox else inactiveBox)
            views.setInt(R.id.box_gunes_light, "setBackgroundResource", if (mevcutVakit == "Güneş") activeBox else inactiveBox)
            views.setInt(R.id.box_ogle_light, "setBackgroundResource", if (mevcutVakit == "Öğle") activeBox else inactiveBox)
            views.setInt(R.id.box_ikindi_light, "setBackgroundResource", if (mevcutVakit == "İkindi") activeBox else inactiveBox)
            views.setInt(R.id.box_aksam_light, "setBackgroundResource", if (mevcutVakit == "Akşam") activeBox else inactiveBox)
            views.setInt(R.id.box_yatsi_light, "setBackgroundResource", if (mevcutVakit == "Yatsı") activeBox else inactiveBox)

            views.setTextViewText(R.id.tv_imsak_light, imsak)
            views.setTextViewText(R.id.tv_gunes_light, gunes)
            views.setTextViewText(R.id.tv_ogle_light, ogle)
            views.setTextViewText(R.id.tv_ikindi_light, ikindi)
            views.setTextViewText(R.id.tv_aksam_light, aksam)
            views.setTextViewText(R.id.tv_yatsi_light, yatsi)

            views.setTextColor(R.id.tv_imsak_light, yaziRengi)
            views.setTextColor(R.id.tv_gunes_light, yaziRengi)
            views.setTextColor(R.id.tv_ogle_light, yaziRengi)
            views.setTextColor(R.id.tv_ikindi_light, yaziRengi)
            views.setTextColor(R.id.tv_aksam_light, yaziRengi)
            views.setTextColor(R.id.tv_yatsi_light, yaziRengi)

            views.setOnClickPendingIntent(R.id.widget_root, WidgetUtils.createLaunchPendingIntent(context))

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
