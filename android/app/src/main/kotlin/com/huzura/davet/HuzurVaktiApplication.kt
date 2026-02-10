package com.huzura.davet

import android.app.Application
import android.util.Log
import com.huzura.davet.widgets.WidgetUpdateReceiver

/**
 * Uygulama sınıfı - Widget güncellemelerini otomatik başlatır
 */
class HuzurVaktiApplication : Application() {
    
    companion object {
        private const val TAG = "HuzurVaktiApplication"
    }
    
    override fun onCreate() {
        super.onCreate()
        
        // Widget güncellemelerini başlat (uygulama kapatılsa bile çalışır)
        Log.d(TAG, "Starting widget update scheduler...")
        WidgetUpdateReceiver.scheduleWidgetUpdates(this)
    }
}
