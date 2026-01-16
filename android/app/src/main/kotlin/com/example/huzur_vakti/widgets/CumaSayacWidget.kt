package com.example.huzur_vakti.widgets

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import com.example.huzur_vakti.R
import es.antonborri.home_widget.HomeWidgetPlugin
import java.util.Calendar

class CumaSayacWidget : AppWidgetProvider() {
    
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
            
            // Cuma namazına kalan süreyi hesapla
            val cumaSayac = hesaplaCumaSayac()
            val cumaTarih = widgetData.getString("cuma_tarih", "Cuma, 12:30") ?: "Cuma, 12:30"
            
            val views = RemoteViews(context.packageName, R.layout.widget_cuma_sayac)
            views.setTextViewText(R.id.tv_cuma_sayac, cumaSayac)
            views.setTextViewText(R.id.tv_cuma_tarih, cumaTarih)
            views.setTextViewText(R.id.tv_cuma_hadis, "\"Cumada bir saat vardır ki, kul o saatte ne isterse Allah verir.\"")
            
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
        
        private fun hesaplaCumaSayac(): String {
            val now = Calendar.getInstance()
            val dayOfWeek = now.get(Calendar.DAY_OF_WEEK)
            val hour = now.get(Calendar.HOUR_OF_DAY)
            
            // Cuma namazı saati (varsayılan 12:30)
            val cumaHour = 12
            val cumaMinute = 30
            
            // Cumaya kalan gün
            var daysUntilFriday = (Calendar.FRIDAY - dayOfWeek + 7) % 7
            
            // Eğer bugün Cuma ve saat geçmişse, bir sonraki Cuma
            if (daysUntilFriday == 0 && (hour > cumaHour || (hour == cumaHour && now.get(Calendar.MINUTE) >= cumaMinute))) {
                daysUntilFriday = 7
            }
            
            // Saat hesaplama
            val targetCalendar = Calendar.getInstance().apply {
                add(Calendar.DAY_OF_MONTH, daysUntilFriday)
                set(Calendar.HOUR_OF_DAY, cumaHour)
                set(Calendar.MINUTE, cumaMinute)
                set(Calendar.SECOND, 0)
            }
            
            val diff = targetCalendar.timeInMillis - now.timeInMillis
            val hours = (diff / (1000 * 60 * 60)) % 24
            val minutes = (diff / (1000 * 60)) % 60
            
            return if (daysUntilFriday > 0) {
                "${daysUntilFriday}g ${String.format("%02d:%02d", hours, minutes)}"
            } else {
                String.format("%02d:%02d", hours, minutes)
            }
        }
    }
}
