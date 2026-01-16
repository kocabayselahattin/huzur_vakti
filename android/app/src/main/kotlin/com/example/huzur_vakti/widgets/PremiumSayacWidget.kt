package com.example.huzur_vakti.widgets

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import com.example.huzur_vakti.R
import es.antonborri.home_widget.HomeWidgetPlugin

class PremiumSayacWidget : AppWidgetProvider() {
    
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
            
            val sonrakiVakit = widgetData.getString("sonraki_vakit", "AKŞAM") ?: "AKŞAM"
            val geriSayim = widgetData.getString("geri_sayim", "02:45:33") ?: "02:45:33"
            val ilerleme = widgetData.getInt("ilerleme", 70)
            val miladiTarih = widgetData.getString("miladi_tarih", "17 Ocak 2026") ?: "17 Ocak 2026"
            val hicriTarih = widgetData.getString("hicri_tarih", "22 Recep 1447") ?: "22 Recep 1447"
            
            val views = RemoteViews(context.packageName, R.layout.widget_premium_sayac)
            views.setTextViewText(R.id.tv_sonraki_vakit_baslik, "${sonrakiVakit.uppercase()} VAKTİNE")
            views.setTextViewText(R.id.tv_geri_sayim, geriSayim)
            views.setProgressBar(R.id.progress_bar, 100, ilerleme, false)
            views.setTextViewText(R.id.tv_miladi, miladiTarih)
            views.setTextViewText(R.id.tv_hicri, hicriTarih)
            
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
