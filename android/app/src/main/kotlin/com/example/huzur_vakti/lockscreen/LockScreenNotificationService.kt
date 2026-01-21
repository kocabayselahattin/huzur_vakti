package com.example.huzur_vakti.lockscreen

import android.app.*
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.util.Log
import android.widget.RemoteViews
import androidx.core.app.NotificationCompat
import com.example.huzur_vakti.MainActivity
import com.example.huzur_vakti.R
import es.antonborri.home_widget.HomeWidgetPlugin
import java.text.SimpleDateFormat
import java.util.*
import android.os.Handler
import android.os.Looper

class LockScreenNotificationService : Service() {

    companion object {
        private const val TAG = "LockScreenService"
        private const val NOTIFICATION_ID = 9999
        private const val CHANNEL_ID = "lock_screen_channel"
        
        // Vakitlerin sıralanması
        private val VAKIT_SIRASI = listOf("Imsak", "Gunes", "Ogle", "Ikindi", "Aksam", "Yatsi")
        private val VAKIT_ISIMLERI = mapOf(
            "Imsak" to "İMSAK",
            "Gunes" to "GÜNEŞ",
            "Ogle" to "ÖĞLE",
            "Ikindi" to "İKİNDİ",
            "Aksam" to "AKŞAM",
            "Yatsi" to "YATSI"
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
            // Her 30 saniyede bir güncelle (geri sayım için)
            handler.postDelayed(this, 30_000)
        }
    }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "Kilit ekranı bildirimi servisi başlatıldı")
        
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
        Log.d(TAG, "Kilit ekranı bildirimi servisi durduruldu")
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
        // Stil tercihini al
        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val stilKey = prefs.getString("flutter.kilit_ekrani_stili", "compact") ?: "compact"
        
        // Vakit verilerini al
        val vakitler = getVakitler()
        val konum = getKonum()
        val sonrakiVakit = getSonrakiVakit(vakitler)
        val kalanSure = hesaplaKalanSure(sonrakiVakit?.second)
        
        // Intent - tıklanınca uygulama açılır
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            Intent(this, MainActivity::class.java),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // RemoteViews ile özel layout
        val remoteViews = when (stilKey) {
            "minimal" -> createMinimalView(vakitler, konum, sonrakiVakit, kalanSure)
            "detailed" -> createDetailedView(vakitler, konum, sonrakiVakit, kalanSure)
            "full" -> createFullView(vakitler, konum, sonrakiVakit, kalanSure)
            else -> createCompactView(vakitler, konum, sonrakiVakit, kalanSure)
        }

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setCustomContentView(remoteViews)
            .setCustomBigContentView(if (stilKey == "full" || stilKey == "detailed") remoteViews else null)
            .setStyle(NotificationCompat.DecoratedCustomViewStyle())
            .setOngoing(true)
            .setAutoCancel(false)
            .setShowWhen(false)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .setContentIntent(pendingIntent)
            .build()
    }

    private fun createCompactView(
        vakitler: Map<String, String>,
        konum: String,
        sonrakiVakit: Pair<String, String>?,
        kalanSure: String
    ): RemoteViews {
        val views = RemoteViews(packageName, R.layout.notification_lock_compact)
        
        views.setTextViewText(R.id.tv_location, konum)
        views.setTextViewText(R.id.tv_next_prayer_name, VAKIT_ISIMLERI[sonrakiVakit?.first] ?: "")
        views.setTextViewText(R.id.tv_next_prayer_time, sonrakiVakit?.second ?: "--:--")
        views.setTextViewText(R.id.tv_countdown, kalanSure)
        
        return views
    }

    private fun createMinimalView(
        vakitler: Map<String, String>,
        konum: String,
        sonrakiVakit: Pair<String, String>?,
        kalanSure: String
    ): RemoteViews {
        val views = RemoteViews(packageName, R.layout.notification_lock_minimal)
        
        views.setTextViewText(R.id.tv_location, konum)
        views.setTextViewText(R.id.tv_next_prayer_name, VAKIT_ISIMLERI[sonrakiVakit?.first] ?: "")
        views.setTextViewText(R.id.tv_next_prayer_time, sonrakiVakit?.second ?: "--:--")
        
        // Minimal stilde "Xs Ydk" formatı (saniye yok)
        views.setTextViewText(R.id.tv_countdown, kalanSure)
        
        return views
    }

    private fun createDetailedView(
        vakitler: Map<String, String>,
        konum: String,
        sonrakiVakit: Pair<String, String>?,
        kalanSure: String
    ): RemoteViews {
        val views = RemoteViews(packageName, R.layout.notification_lock_detailed)
        
        views.setTextViewText(R.id.tv_location, konum)
        views.setTextViewText(R.id.tv_next_prayer_name, VAKIT_ISIMLERI[sonrakiVakit?.first] ?: "")
        views.setTextViewText(R.id.tv_next_prayer_time, sonrakiVakit?.second ?: "--:--")
        views.setTextViewText(R.id.tv_countdown, kalanSure)
        
        // Tüm vakitleri göster
        views.setTextViewText(R.id.tv_imsak, vakitler["Imsak"] ?: "--:--")
        views.setTextViewText(R.id.tv_gunes, vakitler["Gunes"] ?: "--:--")
        views.setTextViewText(R.id.tv_ogle, vakitler["Ogle"] ?: "--:--")
        views.setTextViewText(R.id.tv_ikindi, vakitler["Ikindi"] ?: "--:--")
        views.setTextViewText(R.id.tv_aksam, vakitler["Aksam"] ?: "--:--")
        views.setTextViewText(R.id.tv_yatsi, vakitler["Yatsi"] ?: "--:--")
        
        // Aktif vakti vurgula
        highlightActiveVakit(views, sonrakiVakit?.first)
        
        return views
    }

    private fun createFullView(
        vakitler: Map<String, String>,
        konum: String,
        sonrakiVakit: Pair<String, String>?,
        kalanSure: String
    ): RemoteViews {
        val views = RemoteViews(packageName, R.layout.notification_lock_full)
        
        views.setTextViewText(R.id.tv_location, "📍 $konum")
        views.setTextViewText(R.id.tv_next_prayer_name, VAKIT_ISIMLERI[sonrakiVakit?.first] ?: "")
        views.setTextViewText(R.id.tv_next_prayer_time, sonrakiVakit?.second ?: "--:--")
        
        // "Xs Ydk" formatı (saniye yok - güncelleme her 30sn)
        views.setTextViewText(R.id.tv_countdown, kalanSure)
        
        // Tarihler
        val hicriTarih = HomeWidgetPlugin.getData(this).getString("hicriTarih", "") ?: ""
        val miladiTarih = SimpleDateFormat("dd MMMM yyyy", Locale("tr")).format(Date())
        views.setTextViewText(R.id.tv_hijri_date, hicriTarih)
        views.setTextViewText(R.id.tv_date, miladiTarih)
        
        // Tüm vakitleri göster
        views.setTextViewText(R.id.tv_imsak, vakitler["Imsak"] ?: "--:--")
        views.setTextViewText(R.id.tv_gunes, vakitler["Gunes"] ?: "--:--")
        views.setTextViewText(R.id.tv_ogle, vakitler["Ogle"] ?: "--:--")
        views.setTextViewText(R.id.tv_ikindi, vakitler["Ikindi"] ?: "--:--")
        views.setTextViewText(R.id.tv_aksam, vakitler["Aksam"] ?: "--:--")
        views.setTextViewText(R.id.tv_yatsi, vakitler["Yatsi"] ?: "--:--")
        
        // Aktif vakti vurgula
        highlightActiveVakit(views, sonrakiVakit?.first)
        
        return views
    }

    private fun highlightActiveVakit(views: RemoteViews, aktifVakit: String?) {
        // Aktif vaktin arka planını vurgula
        val boxIds = mapOf(
            "Imsak" to R.id.box_imsak,
            "Gunes" to R.id.box_gunes,
            "Ogle" to R.id.box_ogle,
            "Ikindi" to R.id.box_ikindi,
            "Aksam" to R.id.box_aksam,
            "Yatsi" to R.id.box_yatsi
        )
        
        boxIds.forEach { (vakit, id) ->
            if (vakit == aktifVakit) {
                views.setInt(id, "setBackgroundResource", R.drawable.notification_vakit_active)
            }
        }
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

    private fun getKonum(): String {
        val widgetData = HomeWidgetPlugin.getData(this)
        val il = widgetData.getString("il", "") ?: ""
        val ilce = widgetData.getString("ilce", "") ?: ""
        return if (ilce.isNotEmpty()) ilce else il
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
            "${dakika} dk"
        }
    }

    private fun parseKalanSure(hedefSaat: String?): Triple<Int, Int, Int> {
        if (hedefSaat == null || hedefSaat == "--:--") return Triple(0, 0, 0)
        
        val parts = hedefSaat.split(":")
        if (parts.size != 2) return Triple(0, 0, 0)
        
        val hedefSaatInt = parts[0].toIntOrNull() ?: return Triple(0, 0, 0)
        val hedefDakika = parts[1].toIntOrNull() ?: return Triple(0, 0, 0)
        
        val now = Calendar.getInstance()
        val hedef = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, hedefSaatInt)
            set(Calendar.MINUTE, hedefDakika)
            set(Calendar.SECOND, 0)
        }
        
        if (hedef.before(now)) {
            hedef.add(Calendar.DAY_OF_MONTH, 1)
        }
        
        val farkMs = hedef.timeInMillis - now.timeInMillis
        val farkSaniye = (farkMs / 1000).toInt()
        
        val saat = farkSaniye / 3600
        val dakika = (farkSaniye % 3600) / 60
        val saniye = farkSaniye % 60
        
        return Triple(saat, dakika, saniye)
    }
}
