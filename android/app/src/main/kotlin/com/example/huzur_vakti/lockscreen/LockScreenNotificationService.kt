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
        
        // Çoklu dil desteği için vakit isimleri
        private val VAKIT_ISIMLERI_TR = mapOf(
            "Imsak" to "İMSAK",
            "Gunes" to "GÜNEŞ",
            "Ogle" to "ÖĞLE",
            "Ikindi" to "İKİNDİ",
            "Aksam" to "AKŞAM",
            "Yatsi" to "YATSI"
        )
        
        private val VAKIT_ISIMLERI_EN = mapOf(
            "Imsak" to "FAJR",
            "Gunes" to "SUNRISE",
            "Ogle" to "DHUHR",
            "Ikindi" to "ASR",
            "Aksam" to "MAGHRIB",
            "Yatsi" to "ISHA"
        )
        
        private val VAKIT_ISIMLERI_DE = mapOf(
            "Imsak" to "FADSCHR",
            "Gunes" to "SONNENAUFGANG",
            "Ogle" to "DHUHR",
            "Ikindi" to "ASR",
            "Aksam" to "MAGHRIB",
            "Yatsi" to "ISCHA"
        )
        
        private val VAKIT_ISIMLERI_FR = mapOf(
            "Imsak" to "FAJR",
            "Gunes" to "LEVER DU SOLEIL",
            "Ogle" to "DHUHR",
            "Ikindi" to "ASR",
            "Aksam" to "MAGHRIB",
            "Yatsi" to "ISHA"
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
    
    // Dil ayarlarını al
    private fun getCurrentLanguage(): String {
        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        return prefs.getString("flutter.language", "tr") ?: "tr"
    }
    
    // Dile göre vakit isimlerini al
    private fun getVakitIsimleri(): Map<String, String> {
        return when (getCurrentLanguage()) {
            "en" -> VAKIT_ISIMLERI_EN
            "de" -> VAKIT_ISIMLERI_DE
            "fr" -> VAKIT_ISIMLERI_FR
            else -> VAKIT_ISIMLERI_TR
        }
    }
    
    // Dile göre çeviriler
    private fun getString(key: String): String {
        val lang = getCurrentLanguage()
        return when (key) {
            "app_name" -> when (lang) {
                "en" -> "Huzur Vakti"
                "de" -> "Huzur Vakti"
                "fr" -> "Huzur Vakti"
                else -> "Huzur Vakti"
            }
            "next_prayer" -> when (lang) {
                "en" -> "Next Prayer"
                "de" -> "Nächstes Gebet"
                "fr" -> "Prochaine prière"
                else -> "Sonraki Vakit"
            }
            "remaining" -> when (lang) {
                "en" -> "Remaining"
                "de" -> "Verbleibend"
                "fr" -> "Restant"
                else -> "Kalan"
            }
            "remaining_time" -> when (lang) {
                "en" -> "Remaining Time"
                "de" -> "Verbleibende Zeit"
                "fr" -> "Temps restant"
                else -> "Kalan Süre"
            }
            "time_to" -> when (lang) {
                "en" -> "until"
                "de" -> "bis"
                "fr" -> "jusqu'à"
                else -> "vaktine"
            }
            "imsak" -> getVakitIsimleri()["Imsak"] ?: "İMSAK"
            "gunes" -> getVakitIsimleri()["Gunes"] ?: "GÜNEŞ"
            "ogle" -> getVakitIsimleri()["Ogle"] ?: "ÖĞLE"
            "ikindi" -> getVakitIsimleri()["Ikindi"] ?: "İKİNDİ"
            "aksam" -> getVakitIsimleri()["Aksam"] ?: "AKŞAM"
            "yatsi" -> getVakitIsimleri()["Yatsi"] ?: "YATSI"
            else -> key
        }
    }
    
    // Renk ayarlarını al
    private fun getTextColor(): Int {
        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val hex = prefs.getString("flutter.kilit_yazi_rengi_hex", "FFFFFF") ?: "FFFFFF"
        Log.d(TAG, "📱 Kilit yazı rengi hex: $hex")
        return try {
            android.graphics.Color.parseColor("#$hex")
        } catch (e: Exception) {
            Log.e(TAG, "Renk parse hatası: $hex", e)
            android.graphics.Color.WHITE
        }
    }
    
    private fun getSecondaryTextColor(): Int {
        val textColor = getTextColor()
        // Ana yazı renginin %60 opaklıkta versiyonu
        return android.graphics.Color.argb(
            (255 * 0.6).toInt(),
            android.graphics.Color.red(textColor),
            android.graphics.Color.green(textColor),
            android.graphics.Color.blue(textColor)
        )
    }
    
    private fun getAccentColor(): Int {
        // Turuncu vurgu rengi (sabit)
        return android.graphics.Color.parseColor("#FF7043")
    }
    
    // Arka plan rengini al
    private fun getBackgroundColor(): Int {
        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val index = prefs.getLong("flutter.kilit_arkaplan_index", 0L).toInt()
        
        // Flutter double değerleri String olarak saklar, güvenli okuma
        val opacity = try {
            val opacityStr = prefs.getString("flutter.kilit_seffaflik", "1.0")
            opacityStr?.toDoubleOrNull() ?: 1.0
        } catch (e: Exception) {
            try {
                prefs.getFloat("flutter.kilit_seffaflik", 1.0f).toDouble()
            } catch (e2: Exception) {
                1.0
            }
        }
        
        // Arka plan renk seçenekleri (Flutter'daki ile aynı sıra)
        val colors = listOf(
            0x000000, // Siyah
            0x1A1A2E, // Koyu Lacivert
            0x16213E, // Gece Mavisi
            0x1B1B1B, // Antrasit
            0x2D2D2D, // Koyu Gri
            0x3D3D3D, // Orta Gri
            0xFFFFFF, // Beyaz
            0xF5F5F5  // Açık Gri
        )
        
        val colorIndex = index.coerceIn(0, colors.size - 1)
        val baseColor = colors[colorIndex]
        val alpha = (255 * opacity).toInt().coerceIn(0, 255)
        
        Log.d(TAG, "📱 Kilit arka plan index: $index, opacity: $opacity, alpha: $alpha")
        
        return android.graphics.Color.argb(
            alpha,
            (baseColor shr 16) and 0xFF,
            (baseColor shr 8) and 0xFF,
            baseColor and 0xFF
        )
    }
    
    // RemoteViews'a renkleri uygula
    private fun applyColors(views: RemoteViews) {
        val textColor = getTextColor()
        val secondaryColor = getSecondaryTextColor()
        val accentColor = getAccentColor()
        val backgroundColor = getBackgroundColor()
        
        // Arka plan rengini uygula
        try {
            views.setInt(R.id.notification_root, "setBackgroundColor", backgroundColor)
        } catch (e: Exception) { 
            Log.e(TAG, "Arka plan rengi uygulanamadı: ${e.message}")
        }
        
        // Ana yazı renkleri - tüm metin alanlarına uygulanır
        try {
            // App name
            views.setTextColor(R.id.tv_app_name, textColor)
        } catch (e: Exception) { }
        
        try {
            views.setTextColor(R.id.tv_location, secondaryColor)
        } catch (e: Exception) { }
        
        try {
            views.setTextColor(R.id.tv_next_prayer_name, accentColor)
        } catch (e: Exception) { }
        
        try {
            views.setTextColor(R.id.tv_next_prayer_time, textColor)
        } catch (e: Exception) { }
        
        try {
            views.setTextColor(R.id.tv_countdown, textColor)
        } catch (e: Exception) { }
        
        try {
            views.setTextColor(R.id.tv_next_prayer_label, secondaryColor)
        } catch (e: Exception) { }
        
        try {
            views.setTextColor(R.id.tv_remaining_label, secondaryColor)
        } catch (e: Exception) { }
        
        try {
            views.setTextColor(R.id.tv_time_to_label, secondaryColor)
        } catch (e: Exception) { }
        
        // Vakit saatleri
        try {
            views.setTextColor(R.id.tv_imsak, textColor)
            views.setTextColor(R.id.tv_gunes, textColor)
            views.setTextColor(R.id.tv_ogle, textColor)
            views.setTextColor(R.id.tv_ikindi, textColor)
            views.setTextColor(R.id.tv_aksam, textColor)
            views.setTextColor(R.id.tv_yatsi, textColor)
        } catch (e: Exception) { }
        
        // Vakit etiketleri
        try {
            views.setTextColor(R.id.tv_imsak_label, secondaryColor)
            views.setTextColor(R.id.tv_gunes_label, secondaryColor)
            views.setTextColor(R.id.tv_ogle_label, secondaryColor)
            views.setTextColor(R.id.tv_ikindi_label, secondaryColor)
            views.setTextColor(R.id.tv_aksam_label, secondaryColor)
            views.setTextColor(R.id.tv_yatsi_label, secondaryColor)
        } catch (e: Exception) { }
        
        // Tarihler
        try {
            views.setTextColor(R.id.tv_hijri_date, accentColor)
            views.setTextColor(R.id.tv_date, secondaryColor)
        } catch (e: Exception) { }
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
        val vakitIsimleri = getVakitIsimleri()
        
        views.setTextViewText(R.id.tv_location, konum)
        views.setTextViewText(R.id.tv_next_prayer_name, vakitIsimleri[sonrakiVakit?.first] ?: "")
        views.setTextViewText(R.id.tv_next_prayer_time, sonrakiVakit?.second ?: "--:--")
        views.setTextViewText(R.id.tv_countdown, kalanSure)
        
        // Dil çevirilerini uygula
        views.setTextViewText(R.id.tv_app_name, getString("app_name"))
        views.setTextViewText(R.id.tv_next_prayer_label, getString("next_prayer"))
        views.setTextViewText(R.id.tv_remaining_label, getString("remaining_time"))
        
        // Renkleri uygula
        applyColors(views)
        
        return views
    }

    private fun createMinimalView(
        vakitler: Map<String, String>,
        konum: String,
        sonrakiVakit: Pair<String, String>?,
        kalanSure: String
    ): RemoteViews {
        val views = RemoteViews(packageName, R.layout.notification_lock_minimal)
        val vakitIsimleri = getVakitIsimleri()
        
        views.setTextViewText(R.id.tv_location, konum)
        views.setTextViewText(R.id.tv_next_prayer_name, vakitIsimleri[sonrakiVakit?.first] ?: "")
        views.setTextViewText(R.id.tv_next_prayer_time, sonrakiVakit?.second ?: "--:--")
        
        // Minimal stilde "Xs Ydk" formatı (saniye yok)
        views.setTextViewText(R.id.tv_countdown, kalanSure)
        
        // Renkleri uygula
        applyColors(views)
        
        return views
    }

    private fun createDetailedView(
        vakitler: Map<String, String>,
        konum: String,
        sonrakiVakit: Pair<String, String>?,
        kalanSure: String
    ): RemoteViews {
        val views = RemoteViews(packageName, R.layout.notification_lock_detailed)
        val vakitIsimleri = getVakitIsimleri()
        
        views.setTextViewText(R.id.tv_location, konum)
        views.setTextViewText(R.id.tv_next_prayer_name, vakitIsimleri[sonrakiVakit?.first] ?: "")
        views.setTextViewText(R.id.tv_next_prayer_time, sonrakiVakit?.second ?: "--:--")
        views.setTextViewText(R.id.tv_countdown, kalanSure)
        
        // Dil çevirilerini uygula
        views.setTextViewText(R.id.tv_app_name, getString("app_name"))
        views.setTextViewText(R.id.tv_time_to_label, getString("time_to"))
        
        // Vakit etiketlerini çevir
        views.setTextViewText(R.id.tv_imsak_label, vakitIsimleri["Imsak"])
        views.setTextViewText(R.id.tv_gunes_label, vakitIsimleri["Gunes"])
        views.setTextViewText(R.id.tv_ogle_label, vakitIsimleri["Ogle"])
        views.setTextViewText(R.id.tv_ikindi_label, vakitIsimleri["Ikindi"])
        views.setTextViewText(R.id.tv_aksam_label, vakitIsimleri["Aksam"])
        views.setTextViewText(R.id.tv_yatsi_label, vakitIsimleri["Yatsi"])
        
        // Tüm vakitleri göster
        views.setTextViewText(R.id.tv_imsak, vakitler["Imsak"] ?: "--:--")
        views.setTextViewText(R.id.tv_gunes, vakitler["Gunes"] ?: "--:--")
        views.setTextViewText(R.id.tv_ogle, vakitler["Ogle"] ?: "--:--")
        views.setTextViewText(R.id.tv_ikindi, vakitler["Ikindi"] ?: "--:--")
        views.setTextViewText(R.id.tv_aksam, vakitler["Aksam"] ?: "--:--")
        views.setTextViewText(R.id.tv_yatsi, vakitler["Yatsi"] ?: "--:--")
        
        // Aktif vakti vurgula
        highlightActiveVakit(views, sonrakiVakit?.first)
        
        // Renkleri uygula
        applyColors(views)
        
        return views
    }

    private fun createFullView(
        vakitler: Map<String, String>,
        konum: String,
        sonrakiVakit: Pair<String, String>?,
        kalanSure: String
    ): RemoteViews {
        val views = RemoteViews(packageName, R.layout.notification_lock_full)
        val vakitIsimleri = getVakitIsimleri()
        
        views.setTextViewText(R.id.tv_location, "📍 $konum")
        views.setTextViewText(R.id.tv_next_prayer_name, vakitIsimleri[sonrakiVakit?.first] ?: "")
        views.setTextViewText(R.id.tv_next_prayer_time, sonrakiVakit?.second ?: "--:--")
        
        // "Xs Ydk" formatı (saniye yok - güncelleme her 30sn)
        views.setTextViewText(R.id.tv_countdown, kalanSure)
        
        // Dil çevirilerini uygula
        views.setTextViewText(R.id.tv_app_name, getString("app_name"))
        views.setTextViewText(R.id.tv_next_prayer_label, getString("next_prayer"))
        views.setTextViewText(R.id.tv_remaining_label, getString("remaining"))
        
        // Tarihler
        val hicriTarih = HomeWidgetPlugin.getData(this).getString("hicriTarih", "") ?: ""
        val miladiTarih = SimpleDateFormat("dd MMMM yyyy", Locale("tr")).format(Date())
        views.setTextViewText(R.id.tv_hijri_date, hicriTarih)
        views.setTextViewText(R.id.tv_date, miladiTarih)
        
        // Vakit etiketlerini çevir
        views.setTextViewText(R.id.tv_imsak_label, vakitIsimleri["Imsak"])
        views.setTextViewText(R.id.tv_gunes_label, vakitIsimleri["Gunes"])
        views.setTextViewText(R.id.tv_ogle_label, vakitIsimleri["Ogle"])
        views.setTextViewText(R.id.tv_ikindi_label, vakitIsimleri["Ikindi"])
        views.setTextViewText(R.id.tv_aksam_label, vakitIsimleri["Aksam"])
        views.setTextViewText(R.id.tv_yatsi_label, vakitIsimleri["Yatsi"])
        
        // Tüm vakitleri göster
        views.setTextViewText(R.id.tv_imsak, vakitler["Imsak"] ?: "--:--")
        views.setTextViewText(R.id.tv_gunes, vakitler["Gunes"] ?: "--:--")
        views.setTextViewText(R.id.tv_ogle, vakitler["Ogle"] ?: "--:--")
        views.setTextViewText(R.id.tv_ikindi, vakitler["Ikindi"] ?: "--:--")
        views.setTextViewText(R.id.tv_aksam, vakitler["Aksam"] ?: "--:--")
        views.setTextViewText(R.id.tv_yatsi, vakitler["Yatsi"] ?: "--:--")
        
        // Aktif vakti vurgula
        highlightActiveVakit(views, sonrakiVakit?.first)
        
        // Renkleri uygula
        applyColors(views)
        
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
