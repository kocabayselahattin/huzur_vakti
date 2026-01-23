package com.example.huzur_vakti.alarm

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import com.example.huzur_vakti.lockscreen.LockScreenNotificationService

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
            
            // Kilit ekranı bildirimi aktif mi kontrol et ve başlat
            val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val kilitEkraniBildirimiAktif = prefs.getBoolean("flutter.kilit_ekrani_bildirimi_aktif", false)
            
            if (kilitEkraniBildirimiAktif) {
                Log.d(TAG, "🔒 Kilit ekranı bildirimi servisi başlatılıyor...")
                LockScreenNotificationService.start(context)
            }
            
            Log.d(TAG, "✅ Boot receiver işlemi tamamlandı")
            Log.d(TAG, "   Bildirimler flutter_local_notifications tarafından yeniden zamanlanacak")
        }
    }
}
