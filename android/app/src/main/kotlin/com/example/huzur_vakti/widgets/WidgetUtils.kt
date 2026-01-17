package com.example.huzur_vakti.widgets

import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.os.Build
import android.os.SystemClock
import android.widget.RemoteViews
import com.example.huzur_vakti.MainActivity

object WidgetUtils {
    fun parseColorSafe(hex: String?, defaultColor: Int): Int {
        if (hex.isNullOrBlank()) {
            return defaultColor
        }
        val cleaned = hex.trim()
            .removePrefix("#")
            .removePrefix("0x")
            .removePrefix("0X")

        if (cleaned.length != 6 && cleaned.length != 8) {
            return defaultColor
        }

        return try {
            Color.parseColor("#$cleaned")
        } catch (_: IllegalArgumentException) {
            defaultColor
        }
    }

    fun createLaunchPendingIntent(context: Context): PendingIntent {
        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        return PendingIntent.getActivity(
            context,
            0,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }

    fun applyCountdown(views: RemoteViews, viewId: Int, remaining: String) {
        val parts = remaining.split(":")
        val hours = parts.getOrNull(0)?.toIntOrNull()
        val minutes = parts.getOrNull(1)?.toIntOrNull()
        val seconds = parts.getOrNull(2)?.toIntOrNull() ?: 0
        if (hours == null || minutes == null) {
            views.setTextViewText(viewId, remaining)
            return
        }
        val totalSeconds = (hours * 3600) + (minutes * 60) + seconds
        val base = SystemClock.elapsedRealtime() + (totalSeconds * 1000L)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            views.setChronometerCountDown(viewId, true)
        }
        views.setChronometer(viewId, base, "%s", true)
    }

    fun applyFontStyle(views: RemoteViews, styleRes: Int, vararg viewIds: Int) {
        for (viewId in viewIds) {
            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    views.setInt(viewId, "setTextAppearance", styleRes)
                }
            } catch (_: Throwable) {
                // Ignore font styling failures to avoid widget inflate errors.
            }
        }
    }
}
