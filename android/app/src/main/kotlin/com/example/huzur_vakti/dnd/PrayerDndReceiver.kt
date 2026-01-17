package com.example.huzur_vakti.dnd

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat
import com.example.huzur_vakti.R

class PrayerDndReceiver : BroadcastReceiver() {
  override fun onReceive(context: Context, intent: Intent) {
    val mode = intent.getStringExtra(EXTRA_MODE) ?: return
    val duration = intent.getIntExtra(EXTRA_DURATION, 30)
    val label = intent.getStringExtra(EXTRA_LABEL) ?: "Vakit"

    val notificationManager =
      context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

    if (!notificationManager.isNotificationPolicyAccessGranted) {
      return
    }

    when (mode) {
      MODE_ENABLE -> {
        notificationManager.setInterruptionFilter(NotificationManager.INTERRUPTION_FILTER_NONE)
        showNotification(context, notificationManager, label, duration)
      }
      MODE_DISABLE -> {
        notificationManager.setInterruptionFilter(NotificationManager.INTERRUPTION_FILTER_ALL)
      }
    }
  }

  private fun showNotification(
    context: Context,
    notificationManager: NotificationManager,
    label: String,
    duration: Int,
  ) {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
      val channel = NotificationChannel(
        CHANNEL_ID,
        "Sessize Alma",
        NotificationManager.IMPORTANCE_LOW,
      )
      notificationManager.createNotificationChannel(channel)
    }

    val notification = NotificationCompat.Builder(context, CHANNEL_ID)
      .setSmallIcon(R.mipmap.ic_launcher)
      .setContentTitle("Sessize alındı")
      .setContentText("$label vakti • $duration dk")
      .setAutoCancel(true)
      .build()

    notificationManager.notify((System.currentTimeMillis() % Int.MAX_VALUE).toInt(), notification)
  }

  companion object {
    const val EXTRA_MODE = "mode"
    const val EXTRA_DURATION = "durationMinutes"
    const val EXTRA_LABEL = "label"

    const val MODE_ENABLE = "enable"
    const val MODE_DISABLE = "disable"

    const val CHANNEL_ID = "prayer_dnd_channel"
  }
}
