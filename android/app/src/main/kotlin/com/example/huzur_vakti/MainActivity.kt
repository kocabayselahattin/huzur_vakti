package com.example.huzur_vakti

import android.app.NotificationManager
import android.content.Intent
import android.provider.Settings
import com.example.huzur_vakti.dnd.PrayerDndScheduler
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
	private val channelName = "huzur_vakti/dnd"

	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)

		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
			.setMethodCallHandler { call, result ->
				when (call.method) {
					"hasPolicyAccess" -> {
						val manager = getSystemService(NotificationManager::class.java)
						result.success(manager.isNotificationPolicyAccessGranted)
					}
					"openPolicySettings" -> {
						val intent = Intent(Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS)
						intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
						startActivity(intent)
						result.success(true)
					}
					"scheduleDnd" -> {
						val manager = getSystemService(NotificationManager::class.java)
						if (!manager.isNotificationPolicyAccessGranted) {
							result.success(false)
							return@setMethodCallHandler
						}

						val entries = call.argument<List<Map<String, Any>>>("entries") ?: emptyList()
						val parsed = entries.mapNotNull { entry ->
							val startAt = (entry["startAt"] as? Number)?.toLong() ?: return@mapNotNull null
							val duration = (entry["durationMinutes"] as? Number)?.toInt() ?: 30
							val label = entry["label"]?.toString() ?: "Vakit"
							PrayerDndScheduler.DndEntry(startAt, duration, label)
						}
						PrayerDndScheduler.schedule(this, parsed)
						result.success(true)
					}
					"cancelDnd" -> {
						PrayerDndScheduler.cancelAll(this)
						result.success(true)
					}
					else -> result.notImplemented()
				}
			}
	}
}
