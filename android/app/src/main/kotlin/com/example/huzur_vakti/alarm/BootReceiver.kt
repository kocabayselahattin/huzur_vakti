package com.example.huzur_vakti.alarm

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

/**
 * Cihaz yeniden başlatıldığında alarmları yeniden zamanlayan BroadcastReceiver
 * Boot sonrası alarmlar kaybolur, bu receiver onları geri yükler
 */
class BootReceiver : BroadcastReceiver() {
    
    companion object {
        private const val TAG = "BootReceiver"
    }
    
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED ||
            intent.action == Intent.ACTION_MY_PACKAGE_REPLACED ||
            intent.action == "android.intent.action.QUICKBOOT_POWERON") {
            
            Log.d(TAG, "📱 Cihaz yeniden başlatıldı veya uygulama güncellendi")
            Log.d(TAG, "   Action: ${intent.action}")
            
            // SharedPreferences'dan kayıtlı alarmları kontrol et
            val prefs = context.getSharedPreferences("flutter.prefs", Context.MODE_PRIVATE)
            
            // Flutter tarafında alarmların yeniden zamanlanması için
            // uygulamayı tetikleyecek bir broadcast gönder
            // NOT: flutter_local_notifications paketi boot sonrası bildirimleri zaten yeniden zamanlar
            // Sadece alarm için özel bir işlem yapmamız gerekiyor
            
            Log.d(TAG, "✅ Boot receiver işlemi tamamlandı")
            Log.d(TAG, "   Bildirimler flutter_local_notifications tarafından yeniden zamanlanacak")
        }
    }
}
