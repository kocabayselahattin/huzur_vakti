package com.huzura.davet.lockscreen

import android.app.*
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat
import com.huzura.davet.MainActivity
import com.huzura.davet.R
import es.antonborri.home_widget.HomeWidgetPlugin
import java.util.*
import android.os.Handler
import android.os.Looper

/**
 * Basit kilit ekranı bildirimi servisi
 * Sadece hangi vakitten hangi vakte geçileceği ve kalan süreyi gösterir
 */
class LockScreenNotificationService : Service() {

    companion object {
        private const val TAG = "LockScreenService"
        private const val NOTIFICATION_ID = 9999
        private const val CHANNEL_ID = "lock_screen_channel"
        
        // Vakitlerin sıralanması
        private val VAKIT_SIRASI = listOf("Imsak", "Gunes", "Ogle", "Ikindi", "Aksam", "Yatsi")
        
        // Türkçe vakit isimleri
        private val VAKIT_ISIMLERI = mapOf(
            "Imsak" to "İmsak",
            "Gunes" to "Güneş",
            "Ogle" to "Öğle",
            "Ikindi" to "İkindi",
            "Aksam" to "Akşam",
            "Yatsi" to "Yatsı"
        )

        fun start(context: Context) {
            val intent = Intent(context, LockScreenNotificationService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }

        fun stop(context: Context) {
            context.stopService(Intent(context, LockScreenNotificationService::class.java))
        }
    }

    private val handler = Handler(Looper.getMainLooper())
    private val updateRunnable = object : Runnable {
        override fun run() {
            updateNotification()
            // Her 30 saniyede bir güncelle
            handler.postDelayed(this, 30_000)
        }
    }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "✅ Kilit ekranı bildirimi servisi başlatıldı")
        
        // İlk bildirimi göster
        val notification = createNotification()
        startForeground(NOTIFICATION_ID, notification)
        
        // Periyodik güncelleme başlat
        handler.removeCallbacks(updateRunnable)
        handler.post(updateRunnable)
        
        return START_STICKY
    }

    override fun onDestroy() {
        super.onDestroy()
        handler.removeCallbacks(updateRunnable)
        Log.d(TAG, "🛑 Kilit ekranı bildirimi servisi durduruldu")
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Kilit Ekranı Bildirimi",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Kilit ekranında namaz vakitlerini gösterir"
                setShowBadge(false)
                enableVibration(false)
                setSound(null, null)
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            }
            
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }

    private fun updateNotification() {
        val notification = createNotification()
        val manager = getSystemService(NotificationManager::class.java)
        manager.notify(NOTIFICATION_ID, notification)
    }

    private fun createNotification(): Notification {
        // Vakit verilerini al
        val vakitler = getVakitler()
        val oncekiVakit = getOncekiVakit(vakitler)
        val sonrakiVakit = getSonrakiVakit(vakitler)
        val kalanSure = hesaplaKalanSure(sonrakiVakit?.second)
        
        // Intent - tıklanınca uygulama açılır
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            Intent(this, MainActivity::class.java),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        // Önceki ve sonraki vakit isimleri
        val oncekiIsim = VAKIT_ISIMLERI[oncekiVakit?.first] ?: "-"
        val sonrakiIsim = VAKIT_ISIMLERI[sonrakiVakit?.first] ?: "-"
        val sonrakiSaat = sonrakiVakit?.second ?: "--:--"
        
        // Başlık: Önceki → Sonraki
        val title = "🕌 $oncekiIsim → $sonrakiIsim"
        
        // İçerik: Sonraki saat ve kalan süre
        val content = "⏰ $sonrakiSaat • ⏳ $kalanSure kaldı"

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(title)
            .setContentText(content)
            .setOngoing(true)
            .setAutoCancel(false)
            .setShowWhen(false)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .setContentIntent(pendingIntent)
            .build()
    }

    private fun getVakitler(): Map<String, String> {
        val widgetData = HomeWidgetPlugin.getData(this)
        return mapOf(
            "Imsak" to (widgetData.getString("imsak_saati", "--:--") ?: "--:--"),
            "Gunes" to (widgetData.getString("gunes_saati", "--:--") ?: "--:--"),
            "Ogle" to (widgetData.getString("ogle_saati", "--:--") ?: "--:--"),
            "Ikindi" to (widgetData.getString("ikindi_saati", "--:--") ?: "--:--"),
            "Aksam" to (widgetData.getString("aksam_saati", "--:--") ?: "--:--"),
            "Yatsi" to (widgetData.getString("yatsi_saati", "--:--") ?: "--:--")
        )
    }

    private fun getOncekiVakit(vakitler: Map<String, String>): Pair<String, String>? {
        val now = Calendar.getInstance()
        val currentMinutes = now.get(Calendar.HOUR_OF_DAY) * 60 + now.get(Calendar.MINUTE)
        
        var onceki: Pair<String, String>? = null
        
        for (vakitAdi in VAKIT_SIRASI) {
            val saat = vakitler[vakitAdi] ?: continue
            val parts = saat.split(":")
            if (parts.size == 2) {
                val vakitMinutes = (parts[0].toIntOrNull() ?: 0) * 60 + (parts[1].toIntOrNull() ?: 0)
                if (vakitMinutes <= currentMinutes) {
                    onceki = Pair(vakitAdi, saat)
                } else {
                    break
                }
            }
        }
        
        // Eğer önceki vakit bulunamadıysa (gece yarısından sonra imsak öncesi), dünün yatsısı
        return onceki ?: Pair("Yatsi", vakitler["Yatsi"] ?: "--:--")
    }

    private fun getSonrakiVakit(vakitler: Map<String, String>): Pair<String, String>? {
        val now = Calendar.getInstance()
        val currentMinutes = now.get(Calendar.HOUR_OF_DAY) * 60 + now.get(Calendar.MINUTE)
        
        for (vakitAdi in VAKIT_SIRASI) {
            val saat = vakitler[vakitAdi] ?: continue
            val parts = saat.split(":")
            if (parts.size == 2) {
                val vakitMinutes = (parts[0].toIntOrNull() ?: 0) * 60 + (parts[1].toIntOrNull() ?: 0)
                if (vakitMinutes > currentMinutes) {
                    return Pair(vakitAdi, saat)
                }
            }
        }
        
        // Tüm vakitler geçmişse, yarının ilk vakti (İmsak)
        return Pair("Imsak", vakitler["Imsak"] ?: "--:--")
    }

    private fun hesaplaKalanSure(hedefSaat: String?): String {
        if (hedefSaat == null || hedefSaat == "--:--") return "--:--"
        
        val parts = hedefSaat.split(":")
        if (parts.size != 2) return "--:--"
        
        val hedefSaatInt = parts[0].toIntOrNull() ?: return "--:--"
        val hedefDakika = parts[1].toIntOrNull() ?: return "--:--"
        
        val now = Calendar.getInstance()
        val hedef = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, hedefSaatInt)
            set(Calendar.MINUTE, hedefDakika)
            set(Calendar.SECOND, 0)
        }
        
        // Eğer hedef geçmişse yarına ayarla
        if (hedef.before(now)) {
            hedef.add(Calendar.DAY_OF_MONTH, 1)
        }
        
        val farkMs = hedef.timeInMillis - now.timeInMillis
        val farkDakika = (farkMs / 60000).toInt()
        
        val saat = farkDakika / 60
        val dakika = farkDakika % 60
        
        return if (saat > 0) {
            "${saat}s ${dakika}dk"
        } else {
            "${dakika}dk"
        }
    }
}
