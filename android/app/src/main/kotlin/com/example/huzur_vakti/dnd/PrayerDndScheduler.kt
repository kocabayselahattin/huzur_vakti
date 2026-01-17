package com.example.huzur_vakti.dnd

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent

object PrayerDndScheduler {
  private const val PREFS = "prayer_dnd_prefs"
  private const val KEY_REQUEST_CODES = "request_codes"

  data class DndEntry(
    val startAt: Long,
    val durationMinutes: Int,
    val label: String,
  )

  fun schedule(context: Context, entries: List<DndEntry>) {
    cancelAll(context)

    val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
    val requestCodes = mutableSetOf<String>()
    val now = System.currentTimeMillis()

    for (entry in entries) {
      if (entry.startAt <= now) continue

      val enableCode = requestCode(entry.startAt, false)
      val disableCode = requestCode(entry.startAt, true)
      val endAt = entry.startAt + entry.durationMinutes * 60 * 1000L

      val enableIntent = Intent(context, PrayerDndReceiver::class.java).apply {
        putExtra(PrayerDndReceiver.EXTRA_MODE, PrayerDndReceiver.MODE_ENABLE)
        putExtra(PrayerDndReceiver.EXTRA_DURATION, entry.durationMinutes)
        putExtra(PrayerDndReceiver.EXTRA_LABEL, entry.label)
      }
      val enablePending = PendingIntent.getBroadcast(
        context,
        enableCode,
        enableIntent,
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
      )
      alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, entry.startAt, enablePending)
      requestCodes.add(enableCode.toString())

      val disableIntent = Intent(context, PrayerDndReceiver::class.java).apply {
        putExtra(PrayerDndReceiver.EXTRA_MODE, PrayerDndReceiver.MODE_DISABLE)
        putExtra(PrayerDndReceiver.EXTRA_DURATION, entry.durationMinutes)
        putExtra(PrayerDndReceiver.EXTRA_LABEL, entry.label)
      }
      val disablePending = PendingIntent.getBroadcast(
        context,
        disableCode,
        disableIntent,
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
      )
      alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, endAt, disablePending)
      requestCodes.add(disableCode.toString())
    }

    context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
      .edit()
      .putStringSet(KEY_REQUEST_CODES, requestCodes)
      .apply()
  }

  fun cancelAll(context: Context) {
    val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
    val requestCodes = prefs.getStringSet(KEY_REQUEST_CODES, emptySet()) ?: emptySet()
    val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager

    for (code in requestCodes) {
      val requestCode = code.toIntOrNull() ?: continue
      val intent = Intent(context, PrayerDndReceiver::class.java)
      val pendingIntent = PendingIntent.getBroadcast(
        context,
        requestCode,
        intent,
        PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE,
      )
      pendingIntent?.let {
        alarmManager.cancel(it)
        it.cancel()
      }
    }

    prefs.edit().remove(KEY_REQUEST_CODES).apply()
  }

  private fun requestCode(startAt: Long, disable: Boolean): Int {
    val base = (startAt % Int.MAX_VALUE).toInt().let { if (it < 0) -it else it }
    return if (disable) base + 1 else base
  }
}
