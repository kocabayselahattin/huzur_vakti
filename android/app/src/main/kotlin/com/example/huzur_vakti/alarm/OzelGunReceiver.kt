package com.example.huzur_vakti.alarm

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.RingtoneManager
import android.os.Build
import android.os.PowerManager
import android.util.Log
import androidx.core.app.NotificationCompat
import com.example.huzur_vakti.MainActivity
import com.example.huzur_vakti.R

/**
 * Özel gün/gece bildirimleri için BroadcastReceiver
 * Uygulama kapalı olsa bile çalışır
 */
class OzelGunReceiver : BroadcastReceiver() {
    
    companion object {
        private const val TAG = "OzelGunReceiver"
        const val ACTION_OZEL_GUN_ALARM = "com.example.huzur_vakti.OZEL_GUN_ALARM"
        const val CHANNEL_ID = "ozel_gunler_channel"
        const val NOTIFICATION_ID_BASE = 5000
    }
    
    override fun onReceive(context: Context, intent: Intent) {
        Log.d(TAG, "📢 Özel gün alarmı alındı: ${intent.action}")
        
        if (intent.action == ACTION_OZEL_GUN_ALARM) {
            // Wake lock al
            val powerManager = context.getSystemService(Context.POWER_SERVICE) as PowerManager
            val wakeLock = powerManager.newWakeLock(
                PowerManager.PARTIAL_WAKE_LOCK or PowerManager.ACQUIRE_CAUSES_WAKEUP,
                "HuzurVakti::OzelGunWakeLock"
            )
            wakeLock.acquire(30_000L) // 30 saniye
            
            try {
                val alarmId = intent.getIntExtra("alarm_id", 0)
                val title = intent.getStringExtra("title") ?: "Özel Gün"
                val body = intent.getStringExtra("body") ?: ""
                
                Log.d(TAG, "🕌 Özel gün bildirimi gösteriliyor: $title")
                
                // Bildirim göster
                showOzelGunNotification(context, alarmId, title, body)
                
            } finally {
                if (wakeLock.isHeld) {
                    wakeLock.release()
                }
            }
        }
    }
    
    private fun showOzelGunNotification(context: Context, notificationId: Int, title: String, body: String) {
        val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        
        // Notification channel oluştur (Android 8.0+)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Özel Günler",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Kandiller, bayramlar ve mübarek geceler"
                enableVibration(true)
                enableLights(true)
                setBypassDnd(true)
                lockscreenVisibility = android.app.Notification.VISIBILITY_PUBLIC
                
                // Ses ayarla
                val audioAttributes = AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_NOTIFICATION)
                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                    .build()
                setSound(RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION), audioAttributes)
            }
            notificationManager.createNotificationChannel(channel)
        }
        
        // Ana uygulamayı açacak intent
        val mainIntent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val mainPendingIntent = PendingIntent.getActivity(
            context, notificationId, mainIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        // Bildirim oluştur
        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(NotificationCompat.BigTextStyle().bigText(body))
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setCategory(NotificationCompat.CATEGORY_EVENT)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setContentIntent(mainPendingIntent)
            .setAutoCancel(false) // Kullanıcı silene kadar ekranda kalsın
            .setOngoing(true) // Kalıcı bildirim
            .setDefaults(NotificationCompat.DEFAULT_ALL)
            .setLargeIcon(android.graphics.BitmapFactory.decodeResource(context.resources, R.mipmap.ic_launcher))
            .build()
        
        notificationManager.notify(notificationId, notification)
        Log.d(TAG, "✅ Özel gün bildirimi gösterildi: $title (ID: $notificationId)")
    }
}
