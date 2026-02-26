package com.huzura.davet.alarm

import android.app.AlarmManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.database.ContentObserver
import android.media.AudioAttributes
import android.media.AudioManager
import android.media.MediaPlayer
import android.media.RingtoneManager
import android.media.session.MediaSession
import android.media.session.PlaybackState
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.PowerManager
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.provider.Settings
import android.util.Log
import android.view.KeyEvent
import androidx.core.app.NotificationCompat
import com.huzura.davet.MainActivity
import com.huzura.davet.R
import java.util.Calendar

class AlarmService : Service() {

    companion object {
        private const val TAG = "AlarmService"
        const val NOTIFICATION_ID = 1001
        const val PERSISTENT_NOTIFICATION_ID = 2000 // Alarm bittikten sonra kalan kalıcı bildirim
        const val SILENT_MODE_NOTIFICATION_ID = 2001 // Sessiz mod bildirimi
        const val CHANNEL_ID_ALARM = "huzur_vakti_alarm_channel" // Sesli alarmlar için
        const val CHANNEL_ID_SILENT = "huzur_vakti_silent_channel" // Titreşimli alarmlar için
        const val CHANNEL_ID_PERSISTENT = "huzur_vakti_persistent_channel" // Kalıcı bildirimler için
        const val ACTION_STOP_ALARM = "com.huzura.davet.STOP_ALARM"
        const val ACTION_STAY_SILENT = "com.huzura.davet.STAY_SILENT"  // Kal butonu
        const val ACTION_EXIT_SILENT = "com.huzura.davet.EXIT_SILENT"  // Çık butonu
        const val ACTION_AUTO_EXIT_SILENT = "com.huzura.davet.AUTO_EXIT_SILENT" // Otomatik sessiz moddan çıkış
        private const val AUTO_EXIT_ALARM_ID = 999888 // Otomatik çıkış alarm ID'si
        
        @Volatile
        private var instance: AlarmService? = null
        
        fun isAlarmPlaying(): Boolean = instance?.isPlaying ?: false
        
        fun stopAlarm(context: Context) {
            val intent = Intent(context, AlarmService::class.java).apply {
                action = ACTION_STOP_ALARM
            }
            context.startService(intent)
        }
    }

    private var mediaPlayer: MediaPlayer? = null
    private var vibrator: Vibrator? = null
    private val handler = Handler(Looper.getMainLooper())
    private var wakeLock: PowerManager.WakeLock? = null
    private var isPlaying = false

    // Alarm bilgilerini saklayarak kalıcı bildirim ve sessiz mod için kullanma
    private var currentVakitName = ""
    private var currentIsEarly = false
    private var currentEarlyMinutes = 0
    private var currentIsDailyContent = false
    private var currentContentBody = ""
    private var wasPhoneSilentBefore = false // Alarm başlamadan önce telefon sessiz miydi

    // Ekran kapanma (güç/kilit tuşu) algılama için BroadcastReceiver
    private var screenOffReceiver: BroadcastReceiver? = null

    // MediaSession - donanım tuşlarını yakalama (kulaklık, güç tuşu vb.)
    private var mediaSession: MediaSession? = null

    // Ses tuşu değişikliğini yakalama (ContentObserver)
    private var volumeObserver: ContentObserver? = null

    override fun onCreate() {
        super.onCreate()
        instance = this
        val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
        wakeLock = powerManager.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "HuzurVakti::AlarmServiceWakeLock")
        wakeLock?.setReferenceCounted(false)
        Log.d(TAG, "🔔 AlarmService oluşturuldu")
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        wakeLock?.acquire(3 * 60 * 1000L) // 3 dakika wakelock
        Log.d(TAG, "📢 onStartCommand: ${intent?.action}")

        when (intent?.action) {
            ACTION_STOP_ALARM -> {
                stopAlarm()
                return START_NOT_STICKY
            }
            ACTION_STAY_SILENT -> {
                // Sessiz moda al - alarmı durdur, telefonu sessize al
                Log.d(TAG, "📵 Sessiz moda alınıyor (Kal seçeneği)")
                try {
                    val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
                    audioManager.ringerMode = AudioManager.RINGER_MODE_SILENT
                    Log.d(TAG, "✅ Telefon sessize alındı")
                } catch (e: Exception) {
                    Log.e(TAG, "❌ Sessize alma hatası: ${e.message}")
                }
                stopAlarmInternal()
                showSilentModeNotification()
                scheduleSilentModeAutoExit()
                return START_NOT_STICKY
            }
            ACTION_EXIT_SILENT -> {
                // Sessiz moddan çık - alarmı durdur, telefonu normale döndür
                Log.d(TAG, "🔊 Sessiz moddan çıkılıyor")
                cancelSilentModeAutoExit()
                try {
                    val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
                    audioManager.ringerMode = AudioManager.RINGER_MODE_NORMAL
                    Log.d(TAG, "✅ Telefon normal moda döndü")
                } catch (e: Exception) {
                    Log.e(TAG, "❌ Normal moda dönme hatası: ${e.message}")
                }
                stopAlarmInternal()
                return START_NOT_STICKY
            }
        }

        handleAlarmStart(intent)
        return START_STICKY
    }

    // ===================================================================
    // GÜÇ/KİLİT TUŞU ALGILAMA
    // ===================================================================

    /**
     * Ekran kapanma olayını dinleyen BroadcastReceiver'ı kaydet
     * Güç/kilit tuşuna basıldığında alarm ses+titreşim durdurulur
     */
    private fun registerScreenOffReceiver() {
        if (screenOffReceiver != null) return // Zaten kayıtlı

        screenOffReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                when (intent?.action) {
                    Intent.ACTION_SCREEN_OFF -> {
                        Log.d(TAG, "📴 Ekran kapandı (güç/kilit tuşu), alarm durduruluyor...")
                        stopAlarm()
                    }
                    Intent.ACTION_SCREEN_ON -> {
                        // Ekran tekrar açıldı ama alarm hala çalıyorsa durdur
                        // (İlk tuşta durmadıysa ikinci tuşta kesin durdur)
                        if (isPlaying) {
                            Log.d(TAG, "📱 Ekran açıldı ama alarm hala çalıyor, durduruluyor...")
                            stopAlarm()
                        }
                    }
                }
            }
        }

        val filter = IntentFilter().apply {
            addAction(Intent.ACTION_SCREEN_OFF)
            addAction(Intent.ACTION_SCREEN_ON)
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(screenOffReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            registerReceiver(screenOffReceiver, filter)
        }
        Log.d(TAG, "✅ Ekran kapanma dinleyicisi kaydedildi")
    }

    /**
     * Ekran kapanma dinleyicisini kaldır
     */
    private fun unregisterScreenOffReceiver() {
        screenOffReceiver?.let {
            try {
                unregisterReceiver(it)
                Log.d(TAG, "✅ Ekran kapanma dinleyicisi kaldırıldı")
            } catch (e: Exception) {
                Log.w(TAG, "⚠️ Ekran kapanma dinleyicisi zaten kaldırılmış: ${e.message}")
            }
        }
        screenOffReceiver = null
    }

    // ===================================================================
    // SES TUŞU ALGILAMA (ContentObserver)
    // ===================================================================

    /**
     * Ses seviyesi değişikliklerini dinleyen ContentObserver'ı kaydet.
     * Kullanıcı ses açma/kısma tuşlarına bastığında alarm durdurulur.
     */
    private fun registerVolumeObserver() {
        if (volumeObserver != null) return // Zaten kayıtlı

        volumeObserver = object : ContentObserver(handler) {
            override fun onChange(selfChange: Boolean) {
                super.onChange(selfChange)
                if (isPlaying) {
                    Log.d(TAG, "🔊 Ses seviyesi değişti (ses tuşu), alarm durduruluyor...")
                    stopAlarm()
                }
            }
        }

        try {
            contentResolver.registerContentObserver(
                Settings.System.CONTENT_URI,
                true,
                volumeObserver!!
            )
            Log.d(TAG, "✅ Ses tuşu dinleyicisi (ContentObserver) kaydedildi")
        } catch (e: Exception) {
            Log.e(TAG, "❌ Ses tuşu dinleyicisi kayıt hatası: ${e.message}")
        }
    }

    /**
     * Ses tuşu dinleyicisini kaldır
     */
    private fun unregisterVolumeObserver() {
        volumeObserver?.let {
            try {
                contentResolver.unregisterContentObserver(it)
                Log.d(TAG, "✅ Ses tuşu dinleyicisi kaldırıldı")
            } catch (e: Exception) {
                Log.w(TAG, "⚠️ Ses tuşu dinleyicisi zaten kaldırılmış: ${e.message}")
            }
        }
        volumeObserver = null
    }

    /**
     * MediaSession oluştur - donanım medya tuşlarını yakalamak için
     * Bazı cihazlarda güç tuşu MediaSession üzerinden PAUSE/HEADSETHOOK gönderir
     */
    private fun setupMediaSession() {
        try {
            mediaSession?.release()
            mediaSession = MediaSession(this, "HuzurVaktiAlarm").apply {
                setCallback(object : MediaSession.Callback() {
                    override fun onMediaButtonEvent(mediaButtonIntent: Intent): Boolean {
                        val keyEvent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                            mediaButtonIntent.getParcelableExtra(Intent.EXTRA_KEY_EVENT, KeyEvent::class.java)
                        } else {
                            @Suppress("DEPRECATION")
                            mediaButtonIntent.getParcelableExtra(Intent.EXTRA_KEY_EVENT)
                        }
                        if (keyEvent?.action == KeyEvent.ACTION_DOWN) {
                            when (keyEvent.keyCode) {
                                KeyEvent.KEYCODE_MEDIA_PAUSE,
                                KeyEvent.KEYCODE_MEDIA_STOP,
                                KeyEvent.KEYCODE_HEADSETHOOK,
                                KeyEvent.KEYCODE_MEDIA_PLAY_PAUSE -> {
                                    Log.d(TAG, "🎧 Medya tuşu algılandı: ${keyEvent.keyCode}, alarm durduruluyor...")
                                    stopAlarm()
                                    return true
                                }
                            }
                        }
                        return super.onMediaButtonEvent(mediaButtonIntent)
                    }
                })
                val stateBuilder = PlaybackState.Builder()
                    .setActions(
                        PlaybackState.ACTION_PLAY or PlaybackState.ACTION_PAUSE or
                        PlaybackState.ACTION_STOP or PlaybackState.ACTION_PLAY_PAUSE
                    )
                    .setState(PlaybackState.STATE_PLAYING, 0, 1f)
                setPlaybackState(stateBuilder.build())
                isActive = true
            }
            Log.d(TAG, "✅ MediaSession oluşturuldu ve aktif edildi")
        } catch (e: Exception) {
            Log.e(TAG, "❌ MediaSession oluşturma hatası: ${e.message}")
        }
    }

    /**
     * MediaSession'ı temizle
     */
    private fun releaseMediaSession() {
        try {
            mediaSession?.isActive = false
            mediaSession?.release()
            mediaSession = null
            Log.d(TAG, "✅ MediaSession temizlendi")
        } catch (e: Exception) {
            Log.w(TAG, "⚠️ MediaSession temizleme hatası: ${e.message}")
        }
    }

    // ===================================================================
    // ALARM BAŞLATMA
    // ===================================================================

    private fun handleAlarmStart(intent: Intent?) {
        val vakitName = intent?.getStringExtra(AlarmReceiver.EXTRA_VAKIT_NAME) ?: "Vakit"
        val soundId = intent?.getStringExtra(AlarmReceiver.EXTRA_SOUND_FILE) ?: "best"
        val isEarly = intent?.getBooleanExtra(AlarmReceiver.EXTRA_IS_EARLY, false) ?: false
        val earlyMinutes = intent?.getIntExtra(AlarmReceiver.EXTRA_EARLY_MINUTES, 0) ?: 0
        val contentBody = intent?.getStringExtra("content_body") // Günlük içerik için
        val isDailyContent = intent?.action == "DAILY_CONTENT_ALARM"

        // Alarm bilgilerini sakla (kalıcı bildirim ve sessiz mod için)
        currentVakitName = vakitName
        currentIsEarly = isEarly
        currentEarlyMinutes = earlyMinutes
        currentIsDailyContent = isDailyContent
        currentContentBody = contentBody ?: ""

        Log.d(TAG, "🎶 Gelen ses ID'si: $soundId, Erken: $isEarly, Günlük İçerik: $isDailyContent")

        val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        val ringerMode = audioManager.ringerMode
        val isSilentOrVibrate = ringerMode == AudioManager.RINGER_MODE_SILENT || ringerMode == AudioManager.RINGER_MODE_VIBRATE

        // Alarm başlamadan önce telefonun sessiz durumunu kaydet
        wasPhoneSilentBefore = isSilentOrVibrate

        Log.d(TAG, "📱 Telefon modu: $ringerMode (Sessiz/Titreşim: $isSilentOrVibrate)")
        
        createNotificationChannels()

        val channelId = if (isSilentOrVibrate) CHANNEL_ID_SILENT else CHANNEL_ID_ALARM
        val notification = if (isDailyContent) {
            createDailyContentNotification(vakitName, contentBody ?: "", channelId)
        } else {
            createAlarmNotification(vakitName, isEarly, earlyMinutes, channelId)
        }
        startForeground(NOTIFICATION_ID, notification)

        // Güç/kilit tuşu ve ses tuşu algılama için dinleyicileri kur
        registerScreenOffReceiver()
        setupMediaSession()
        registerVolumeObserver()

        if (isSilentOrVibrate) {
            Log.d(TAG, "📳 Telefon sessizde, sadece titreşim.")
            startVibration()
        } else {
            Log.d(TAG, "🔊 Ses çalınıyor: $soundId")
            playSound(soundId)
            startVibration() // Sesle birlikte titreşim de olsun
        }
    }

    /**
     * Ses ID'sinden Android resource ID'sine dönüşüm
     * Flutter tarafından gelen ID'ler ("best", "aksam_ezani" vs.) direkt mapping ile eşleşiyor
     */
    private fun getSoundResourceId(soundId: String): Int {
        return when(soundId.lowercase().trim()) {
            "aksam_ezani" -> R.raw.aksam_ezani
            "aksam_ezani_segah" -> R.raw.aksam_ezani_segah
            "ayasofya_ezan_sesi" -> R.raw.ayasofya_ezan_sesi
            "best" -> R.raw.best
            "corner" -> R.raw.corner
            "ding_dong" -> R.raw.ding_dong
            "esselatu_hayrun_minen_nevm1" -> R.raw.esselatu_hayrun_minen_nevm1
            "esselatu_hayrun_minen_nevm2" -> R.raw.esselatu_hayrun_minen_nevm2
            "ikindi_ezani_hicaz" -> R.raw.ikindi_ezani_hicaz
            "melodi" -> R.raw.melodi
            "mescid_i_nebi_sabah_ezani" -> R.raw.mescid_i_nebi_sabah_ezani
            "ney_uyan" -> R.raw.ney_uyan
            "ogle_ezani_rast" -> R.raw.ogle_ezani_rast
            "sabah_ezani_saba" -> R.raw.sabah_ezani_saba
            "snaps" -> R.raw.snaps
            "sweet_favour" -> R.raw.sweet_favour
            "violet" -> R.raw.violet
            "yatsi_ezani_ussak" -> R.raw.yatsi_ezani_ussak
            else -> {
                Log.w(TAG, "⚠️ Bilinmeyen ses ID'si: $soundId, varsayılan 'best' kullanılıyor")
                R.raw.best
            }
        }
    }

    private fun playSound(soundId: String) {
        mediaPlayer?.release()
        val resId = getSoundResourceId(soundId)
        Log.d(TAG, "🎵 Ses çalınıyor - ID: $soundId, Resource ID: $resId")

        mediaPlayer = MediaPlayer().apply {
            setDataSource(applicationContext, android.net.Uri.parse("android.resource://$packageName/$resId"))
            setAudioAttributes(
                AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_ALARM)
                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                    .build()
            )
            isLooping = false
            prepareAsync()
            setOnPreparedListener {
                it.start()
                this@AlarmService.isPlaying = true
            }
            setOnCompletionListener {
                Log.d(TAG, "✅ Ses dosyası tamamlandı, alarm durduruluyor.")
                stopAlarm()
            }
            setOnErrorListener { _, _, _ ->
                Log.e(TAG, "❌ MediaPlayer hatası")
                this@AlarmService.isPlaying = false
                stopAlarm()
                true
            }
        }
    }

    private fun startVibration() {
        vibrator?.cancel()
        vibrator = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val vibratorManager = getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as VibratorManager
            vibratorManager.defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
        }
        vibrator?.vibrate(VibrationEffect.createWaveform(longArrayOf(0, 500, 500), 0))
    }

    private fun stopAlarm() {
        Log.d(TAG, "🔇 Alarm durduruluyor...")

        // Güç/kilit tuşu ve ses tuşu dinleyicilerini temizle
        unregisterScreenOffReceiver()
        releaseMediaSession()
        unregisterVolumeObserver()

        // Sessiz mod kontrolü: Vaktinde bildirim + sessiz mod açık + telefon başta sessiz değildi
        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val isSessizeAlEnabled = prefs.getBoolean("flutter.sessize_al", false)
        val shouldActivateSilentMode = !currentIsEarly && !currentIsDailyContent && isSessizeAlEnabled && !wasPhoneSilentBefore

        if (shouldActivateSilentMode) {
            // Telefonu sessize al
            Log.d(TAG, "📵 Sessiz mod aktif ediliyor...")
            try {
                val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
                audioManager.ringerMode = AudioManager.RINGER_MODE_SILENT
                Log.d(TAG, "✅ Telefon sessize alındı")
            } catch (e: Exception) {
                Log.e(TAG, "❌ Sessize alma hatası: ${e.message}")
            }
        }

        // Ses ve titreşimi durdur
        stopAlarmInternal()

        // Sessiz mod bildirimi veya normal kalıcı bildirim göster
        if (shouldActivateSilentMode) {
            showSilentModeNotification()
            scheduleSilentModeAutoExit()
        } else {
            showPersistentNotification()
        }
    }

    /**
     * Sadece ses ve titreşimi durdurur, servisi kapatır
     * Bildirim göstermez (çağıran metot kendi bildirimini gösterir)
     */
    private fun stopAlarmInternal() {
        Log.d(TAG, "🔇 Ses ve titreşim durduruluyor...")
        handler.removeCallbacksAndMessages(null)

        // Güç/kilit tuşu ve ses tuşu dinleyicilerini temizle
        unregisterScreenOffReceiver()
        releaseMediaSession()
        unregisterVolumeObserver()

        if (mediaPlayer?.isPlaying == true) {
            mediaPlayer?.stop()
        }
        mediaPlayer?.release()
        mediaPlayer = null
        isPlaying = false
        vibrator?.cancel()

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopForeground(STOP_FOREGROUND_REMOVE)
        } else {
            @Suppress("DEPRECATION")
            stopForeground(true)
        }
        stopSelf()
    }

    // ===================================================================
    // KALICI BİLDİRİMLER
    // ===================================================================

    /**
     * Alarm bittikten sonra kalıcı bildirim göster
     * Bu bildirim kullanıcı elle kapatana kadar kalır
     */
    private fun showPersistentNotification() {
        val notificationManager = getSystemService(NotificationManager::class.java)
        createPersistentChannel(notificationManager)

        val mainIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val mainPendingIntent = PendingIntent.getActivity(
            this, 10, mainIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val title: String
        val body: String
        when {
            currentIsDailyContent -> {
                title = currentVakitName
                body = currentContentBody.ifEmpty { "Günlük içerik bildirimi" }
            }
            currentIsEarly -> {
                title = "${currentVakitName} Vakti Yaklaşıyor"
                body = "${currentVakitName} vaktine ${currentEarlyMinutes} dakika kaldı."
            }
            else -> {
                title = "${currentVakitName} Vakti Girdi"
                body = "Hayırlı ibadetler!"
            }
        }

        val notification = NotificationCompat.Builder(this, CHANNEL_ID_PERSISTENT)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(NotificationCompat.BigTextStyle().bigText(body))
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setContentIntent(mainPendingIntent)
            .setAutoCancel(false) // Ses bitince otomatik kaybolmasın
            .setOngoing(false) // Kullanıcı kaydırarak kapatabilir
            .build()

        notificationManager.notify(PERSISTENT_NOTIFICATION_ID, notification)
        Log.d(TAG, "✅ Kalıcı bildirim gösterildi: $title")
    }

    /**
     * Sessiz mod bildirimi göster
     * "Kal" (sessiz modda kal) ve "Çık" (normale dön) seçenekleri sunar
     */
    private fun showSilentModeNotification() {
        val notificationManager = getSystemService(NotificationManager::class.java)
        createPersistentChannel(notificationManager)

        val mainIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val mainPendingIntent = PendingIntent.getActivity(
            this, 10, mainIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // "Kal" butonu - sessiz modda kal, bildirimi kapat
        val stayIntent = Intent(this, SilentModeReceiver::class.java).apply {
            action = ACTION_STAY_SILENT
        }
        val stayPendingIntent = PendingIntent.getBroadcast(
            this, 20, stayIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // "Çık" butonu - sessiz moddan çık, bildirimi kapat
        val exitIntent = Intent(this, SilentModeReceiver::class.java).apply {
            action = ACTION_EXIT_SILENT
        }
        val exitPendingIntent = PendingIntent.getBroadcast(
            this, 21, exitIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // Cuma günü Öğle vakti = 60 dk, diğerleri = 30 dk
        val silentDurationMinutes = getSilentDurationMinutes()

        val title = "📵 Sessiz Mod Aktif"
        val body = "${currentVakitName} vakti nedeniyle telefonunuz sessize alındı.\n${silentDurationMinutes} dakika sonra otomatik olarak sessiz moddan çıkılacak.\nSessiz modda kalmak veya şimdi çıkmak için seçim yapın."

        val notification = NotificationCompat.Builder(this, CHANNEL_ID_PERSISTENT)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(NotificationCompat.BigTextStyle().bigText(body))
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setContentIntent(mainPendingIntent)
            .setAutoCancel(false) // Butonlara basılmadan kapanmasın
            .setOngoing(true) // Kaydırarak kapatılamasın, buton seçimi zorunlu
            .addAction(0, "📵 Kal", stayPendingIntent)
            .addAction(0, "🔊 Çık", exitPendingIntent)
            .build()

        notificationManager.notify(SILENT_MODE_NOTIFICATION_ID, notification)
        Log.d(TAG, "✅ Sessiz mod bildirimi gösterildi ($silentDurationMinutes dk)")
    }

    /**
     * Kalıcı bildirimler için kanal oluştur
     */
    private fun createPersistentChannel(notificationManager: NotificationManager) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID_PERSISTENT,
                "Alarm Bildirimleri",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Alarm sonrası kalıcı bildirimler"
                setSound(null, null)
                enableVibration(false)
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            }
            notificationManager.createNotificationChannel(channel)
        }
    }

    // ===================================================================
    // OTOMATİK SESSİZ MODDAN ÇIKIŞ ZAMANLAYICISI
    // ===================================================================

    /**
     * Sessiz mod süresi hesapla
     * Cuma günü Öğle vakti (Cuma namazı) = 60 dakika
     * Diğer tüm vakitler = 30 dakika
     */
    private fun getSilentDurationMinutes(): Int {
        val calendar = Calendar.getInstance()
        val isFriday = calendar.get(Calendar.DAY_OF_WEEK) == Calendar.FRIDAY
        val normalizedVakit = normalizeVakitName(currentVakitName)
        val isCumaOgle = isFriday && normalizedVakit == "ogle"
        val duration = if (isCumaOgle) 60 else 30
        Log.d(TAG, "⏱️ Sessiz mod süresi: $duration dk (Cuma=${isFriday}, Vakit=${normalizedVakit})")
        return duration
    }

    /**
     * Otomatik sessiz moddan çıkış alarmı zamanla
     * Süre bitince SilentModeReceiver'a AUTO_EXIT_SILENT gönderilir
     */
    private fun scheduleSilentModeAutoExit() {
        val durationMinutes = getSilentDurationMinutes()
        val triggerAtMillis = System.currentTimeMillis() + (durationMinutes * 60 * 1000L)

        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(this, SilentModeReceiver::class.java).apply {
            action = ACTION_AUTO_EXIT_SILENT
        }
        val pendingIntent = PendingIntent.getBroadcast(
            this, AUTO_EXIT_ALARM_ID, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                alarmManager.setExactAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    triggerAtMillis,
                    pendingIntent
                )
            } else {
                alarmManager.setExact(
                    AlarmManager.RTC_WAKEUP,
                    triggerAtMillis,
                    pendingIntent
                )
            }
            val exitTime = java.text.SimpleDateFormat("HH:mm:ss", java.util.Locale.getDefault())
                .format(java.util.Date(triggerAtMillis))
            Log.d(TAG, "⏰ Sessiz mod otomatik çıkış zamanlandı: $exitTime ($durationMinutes dk sonra)")
        } catch (e: Exception) {
            Log.e(TAG, "❌ Otomatik çıkış zamanlama hatası: ${e.message}")
        }
    }

    /**
     * Otomatik sessiz moddan çıkış alarmını iptal et
     * Kullanıcı "Kal" veya "Çık" butonuna bastığında çağrılır
     */
    private fun cancelSilentModeAutoExit() {
        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(this, SilentModeReceiver::class.java).apply {
            action = ACTION_AUTO_EXIT_SILENT
        }
        val pendingIntent = PendingIntent.getBroadcast(
            this, AUTO_EXIT_ALARM_ID, intent,
            PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE
        )
        if (pendingIntent != null) {
            alarmManager.cancel(pendingIntent)
            pendingIntent.cancel()
            Log.d(TAG, "🚫 Sessiz mod otomatik çıkış alarmı iptal edildi")
        }
    }

    private fun createNotificationChannels() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val notificationManager = getSystemService(NotificationManager::class.java)

            // Sesli alarmlar için kanal
            val alarmChannel = NotificationChannel(
                CHANNEL_ID_ALARM,
                "Vakit Alarmları (Sesli)",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Sesli namaz vakti alarmları"
                setBypassDnd(true)
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
                setSound(null, null) // Sesi biz çalacağımız için null
                enableVibration(false) // Titreşimi biz yöneteceğiz
            }
            notificationManager.createNotificationChannel(alarmChannel)

            // Sessiz/Titreşimli alarmlar için kanal
            val silentChannel = NotificationChannel(
                CHANNEL_ID_SILENT,
                "Vakit Alarmları (Sessiz)",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Sessiz modda gösterilen titreşimli alarmlar"
                setBypassDnd(true)
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
                setSound(null, null)
                enableVibration(true) // Sadece titreşim için kanala güvenebiliriz
            }
            notificationManager.createNotificationChannel(silentChannel)
        }
    }

    private fun createAlarmNotification(vakitName: String, isEarly: Boolean, earlyMinutes: Int, channelId: String): Notification {
        val mainIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val mainPendingIntent = PendingIntent.getActivity(
            this, 0, mainIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val stopIntent = Intent(this, AlarmService::class.java).apply { action = ACTION_STOP_ALARM }
        val stopPendingIntent = PendingIntent.getService(
            this, 1, stopIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val title = if (isEarly) "$vakitName Vakti Yaklaşıyor" else "$vakitName Vakti Girdi"
        val body = if (isEarly) "$vakitName vaktine $earlyMinutes dakika kaldı." else "Hayırlı ibadetler!"

        return NotificationCompat.Builder(this, channelId)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(title)
            .setContentText(body)
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setContentIntent(stopPendingIntent) // Bildirime tıklayınca sesi durdur
            .setFullScreenIntent(mainPendingIntent, true)
            .setAutoCancel(true) // Tıklayınca bildirim kapansın ve ses dursun
            .addAction(0, "Kapat", stopPendingIntent)
            .build()
    }

    private fun createDailyContentNotification(title: String, body: String, channelId: String): Notification {
        val mainIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val mainPendingIntent = PendingIntent.getActivity(
            this, 0, mainIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val stopIntent = Intent(this, AlarmService::class.java).apply { action = ACTION_STOP_ALARM }
        val stopPendingIntent = PendingIntent.getService(
            this, 1, stopIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        return NotificationCompat.Builder(this, channelId)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(NotificationCompat.BigTextStyle().bigText(body))
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setContentIntent(stopPendingIntent) // Bildirime tıklayınca sesi durdur
            .setAutoCancel(true) // Tıklayınca bildirim kapansın ve ses dursun
            .setOngoing(false)
            .addAction(R.drawable.ic_launcher_foreground, "Kapat", stopPendingIntent)
            .build()
    }

    /**
     * DEPRECATED: Artık kullanılmıyor, geriye dönük uyumluluk için bırakılmış
     * Ses ID'si direkt Flutter'dan geliyor ve getSoundResourceId() ile map ediliyor
     */

    private fun normalizeVakitName(vakitName: String): String {
        val normalized = vakitName.lowercase(java.util.Locale("tr", "TR"))
        return when {
            normalized.contains("imsak") -> "imsak"
            normalized.contains("gunes") -> "gunes"
            normalized.contains("ogle") -> "ogle"
            normalized.contains("ikindi") -> "ikindi"
            normalized.contains("aksam") -> "aksam"
            normalized.contains("yatsi") -> "yatsi"
            else -> ""
        }
    }
    override fun onDestroy() {
        // Ses ve titreşimi temizle
        handler.removeCallbacksAndMessages(null)
        if (mediaPlayer?.isPlaying == true) {
            mediaPlayer?.stop()
        }
        mediaPlayer?.release()
        mediaPlayer = null
        isPlaying = false
        vibrator?.cancel()

        // Güç/kilit tuşu ve ses tuşu dinleyicilerini temizle
        unregisterScreenOffReceiver()
        releaseMediaSession()
        unregisterVolumeObserver()

        wakeLock?.release()
        instance = null
        super.onDestroy()
        Log.d(TAG, "🔔 AlarmService sonlandırıldı")
    }
}
