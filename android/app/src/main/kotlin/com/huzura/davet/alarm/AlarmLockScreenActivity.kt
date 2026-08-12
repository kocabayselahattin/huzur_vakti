package com.huzura.davet.alarm

import android.app.Activity
import android.app.KeyguardManager
import android.content.Context
import android.content.Intent
import android.media.AudioManager
import android.os.Build
import android.os.Bundle
import android.view.KeyEvent
import android.view.View
import android.view.WindowManager
import android.widget.Button
import android.widget.TextView
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.WindowInsetsControllerCompat
import com.huzura.davet.R
import es.antonborri.home_widget.HomeWidgetPlugin
import java.text.SimpleDateFormat
import java.util.*

/**
 * Kilit ekranında görünen alarm activity'si
 * 
 * ERKEN BİLDİRİM:
 * - Sadece "Kapat" butonu
 * - Tuşlarla kapatılabilir
 * - Telefonu sessize ALMAZ
 * 
 * VAKTİNDE BİLDİRİM + SESSİZE AL AÇIK:
 * - "Kal" (sessiz modda kal) ve "Çık" (normale dön) butonları
 * - Tuşla kapatınca telefonu sessize alır
 * 
 * VAKTİNDE BİLDİRİM + SESSİZE AL KAPALI:
 * - Sadece "Kapat" butonu
 * - Tuşlarla kapatılabilir
 * - Telefonu sessize ALMAZ
 */
class AlarmLockScreenActivity : Activity() {
    
    private var vakitName = ""
    private var vakitTime = ""
    private var isEarly = false
    private var earlyMinutes = 0
    private var isSessizeAlEnabled = false
    private var wasPhoneSilentBefore = false
    private var hasResumed = false  // Tek tuşla susturma için resume takibi
    private var isDismissed = false // Çift kapanmayı önle
    
    // Motivasyon sözleri
    private val motivasyonSozleri = listOf(
        "Namaz müminin miracıdır.",
        "Sabır ve namazla Allah'tan yardım isteyin.",
        "Namaz, kötülüklerden alıkoyar.",
        "Namazı dosdoğru kılın.",
        "Namaz dinin direğidir.",
        "Hayırlı ibadetler!",
        "Allah kabul etsin.",
        "Rahmet kapıları açık!",
        "Dualarınız kabul olsun."
    )
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        hasResumed = true // İlk tuşta çalışması için hemen true yap
        
        // Kilit ekranı üzerinde göster
        setupLockScreenFlags()
        
        // Intent'ten verileri al
        vakitName = intent.getStringExtra(AlarmReceiver.EXTRA_VAKIT_NAME) ?: "Vakit"
        vakitTime = intent.getStringExtra(AlarmReceiver.EXTRA_VAKIT_TIME) ?: ""
        isEarly = intent.getBooleanExtra(AlarmReceiver.EXTRA_IS_EARLY, false)
        earlyMinutes = intent.getIntExtra(AlarmReceiver.EXTRA_EARLY_MINUTES, 0)
        wasPhoneSilentBefore = intent.getBooleanExtra("was_phone_silent", false)
        
        // Vakitlerde sessize al ayarı
        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        isSessizeAlEnabled = prefs.getBoolean("flutter.sessize_al", false)
        
        // UI'ı oluştur
        setContentView(R.layout.activity_alarm_lock_screen)
        setupUI()
    }
    
    private fun setupLockScreenFlags() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
            
            val keyguardManager = getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager
            keyguardManager.requestDismissKeyguard(this, null)
        } else {
            @Suppress("DEPRECATION")
            window.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD or
                WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
                // FLAG_KEEP_SCREEN_ON kasıtlı kaldırıldı: ekranı açık tutunca
                // güç/kilit tuşu etkisizleşiyordu.
            )
        }
        
        // Modern edge-to-edge fullscreen handling.
        // Android 15 (API 35) ve üzeri uçtan uca çizer; setDecorFitsSystemWindows
        // orada kullanımdan kaldırıldığı için yalnızca eski sürümlerde çağrılır.
        if (Build.VERSION.SDK_INT < 35) {
            @Suppress("DEPRECATION")
            WindowCompat.setDecorFitsSystemWindows(window, false)
        }
        WindowCompat.getInsetsController(window, window.decorView)?.let { controller ->
            controller.systemBarsBehavior =
                WindowInsetsControllerCompat.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
            controller.hide(WindowInsetsCompat.Type.systemBars())
        }
    }
    
    private fun setupUI() {
        // Widget verilerinden konum ve tarih al
        val widgetData = HomeWidgetPlugin.getData(this)
        val konum = widgetData.getString("konum", "İstanbul") ?: "İstanbul"
        val hicriTarih = widgetData.getString("hicri_tarih", "") ?: ""
        
        // Miladi tarih
        val miladiTarih = SimpleDateFormat("dd MMMM yyyy", Locale("tr", "TR")).format(Date())
        
        // Konum
        findViewById<TextView>(R.id.tv_location)?.text = konum
        
        // Tarih (Miladi + Hicri)
        val tarihText = if (hicriTarih.isNotEmpty()) {
            "$miladiTarih • $hicriTarih"
        } else {
            miladiTarih
        }
        findViewById<TextView>(R.id.tv_date)?.text = tarihText
        
        // Başlık
        findViewById<TextView>(R.id.tv_alarm_title)?.text = "${vakitName.uppercase()} NAMAZI"
        
        // Alt yazı
        findViewById<TextView>(R.id.tv_alarm_subtitle)?.text = if (isEarly) {
            "⏰ $earlyMinutes dakika kaldı"
        } else {
            "✨ Hayırlı ibadetler ✨"
        }
        
        // Saat
        findViewById<TextView>(R.id.tv_alarm_time)?.text = vakitTime
        
        // Motivasyon sözü
        val randomSoz = motivasyonSozleri.random()
        findViewById<TextView>(R.id.tv_quote)?.text = randomSoz
        
        // Hilal ikonu - vakite göre değişsin
        val moonIcon = when (vakitName.lowercase()) {
            "imsak", "yatsı" -> "🌙"
            "güneş", "gunes" -> "🌅"
            "öğle", "ogle" -> "☀️"
            "ikindi" -> "🌤️"
            "akşam", "aksam" -> "🌆"
            else -> "☪"
        }
        findViewById<TextView>(R.id.tv_moon_icon)?.text = moonIcon
        
        // Butonları ayarla
        val btnDismiss = findViewById<Button>(R.id.btn_dismiss)
        val btnStay = findViewById<Button>(R.id.btn_stay)
        val btnExit = findViewById<Button>(R.id.btn_exit)
        val tvHint = findViewById<TextView>(R.id.tv_hint)
        
        if (isEarly) {
            // ERKEN BİLDİRİM - sadece Kapat butonu, sessize alma yok
            btnDismiss?.visibility = View.VISIBLE
            btnStay?.visibility = View.GONE
            btnExit?.visibility = View.GONE
            
            btnDismiss?.setOnClickListener {
                dismissAlarm()
            }
            
            tvHint?.text = "Kilit/ses tuşuna tek basışla kapatabilirsiniz"

        } else if (isSessizeAlEnabled && !wasPhoneSilentBefore) {
            // VAKTİNDE BİLDİRİM + SESSİZE AL AÇIK + telefon başta sessiz değildi
            // Kal ve Çık butonlarını göster
            btnDismiss?.visibility = View.GONE
            btnStay?.visibility = View.VISIBLE
            btnExit?.visibility = View.VISIBLE
            
            // "Kal" butonu - sessize al ve kapat
            btnStay?.setOnClickListener {
                dismissAlarmWithSilentAction(AlarmService.ACTION_STAY_SILENT)
            }
            
            // "Çık" butonu - normale dön ve kapat
            btnExit?.setOnClickListener {
                dismissAlarmWithSilentAction(AlarmService.ACTION_EXIT_SILENT)
            }
            
            tvHint?.text = "Kilit tuşuna tek basışla sessize alınır"
            
        } else {
            // VAKTİNDE BİLDİRİM + SESSİZE AL KAPALI veya telefon zaten sessizdi
            // Sadece Kapat butonu
            btnDismiss?.visibility = View.VISIBLE
            btnStay?.visibility = View.GONE
            btnExit?.visibility = View.GONE
            
            btnDismiss?.setOnClickListener {
                dismissAlarm()
            }
            
            tvHint?.text = "Kilit/ses tuşuna tek basışla kapatabilirsiniz"
        }
    }
    
    override fun onResume() {
        super.onResume()
        hasResumed = true
    }

    /**
     * Güç/kilit tuşuna TEK basışta alarm susturma — Android 12+ dahil tüm sürümler.
     * onUserLeaveHint(), kullanıcı güç/home/son-uygulamalar tuşuyla aktiviteden
     * ayrılırken Android tarafından anında çağrılır; KEYCODE_POWER'a gerek yok.
     */
    override fun onUserLeaveHint() {
        super.onUserLeaveHint()
        if (hasResumed) {
            handleDismiss()
        }
    }

    /**
     * Ekran kapandığında (güç tuşu vb.) güvence olarak da durdur.
     */
    override fun onPause() {
        super.onPause()
        if (hasResumed) {
            handleDismiss()
        }
    }

    /**
     * Activity tamamen görünmez olursa kesin durdur (backup).
     */
    override fun onStop() {
        super.onStop()
        if (!isDismissed) {
            handleDismiss()
        }
    }

    /**
     * Sessize alma ayarına göre tek noktada kapatma mantığı.
     */
    private fun handleDismiss() {
        if (isDismissed) return
        isDismissed = true
        if (isEarly || !isSessizeAlEnabled || wasPhoneSilentBefore) {
            dismissAlarm()
        } else {
            dismissAlarmWithSilentAction(AlarmService.ACTION_STAY_SILENT)
        }
    }

    override fun onKeyDown(keyCode: Int, event: KeyEvent?): Boolean {
        when (keyCode) {
            KeyEvent.KEYCODE_VOLUME_UP,
            KeyEvent.KEYCODE_VOLUME_DOWN,
            KeyEvent.KEYCODE_POWER,
            KeyEvent.KEYCODE_HEADSETHOOK -> {
                handleDismiss()
                return true
            }
        }
        return super.onKeyDown(keyCode, event)
    }
    
    @Deprecated("Deprecated in Java")
    override fun onBackPressed() {
        handleDismiss()
    }
    
    /**
     * Alarmı tamamen kapat (sessize almadan)
     */
    private fun dismissAlarm() {
        if (!isDismissed) isDismissed = true
        // Ekranı tekrar açma flag'ini kapat ki finish sonrası ekran geri gelmesin
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setTurnScreenOn(false)
        }
        AlarmService.stopAlarm(this)
        finish()
    }
    
    /**
     * Alarmı kapat ve sessize al action'ını tetikle
     */
    private fun dismissAlarmWithSilentAction(action: String) {
        if (!isDismissed) isDismissed = true
        // Ekranı tekrar açma flag'ini kapat ki finish sonrası ekran geri gelmesin
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setTurnScreenOn(false)
        }
        val intent = Intent(this, AlarmService::class.java).apply {
            this.action = action
        }
        startService(intent)
        finish()
    }
    
    override fun onDestroy() {
        super.onDestroy()
    }
}
