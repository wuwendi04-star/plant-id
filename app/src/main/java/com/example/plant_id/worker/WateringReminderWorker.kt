package com.example.plant_id.worker

import android.content.Context
import androidx.work.CoroutineWorker
import androidx.work.WorkerParameters
import com.example.plant_id.data.database.PlantDatabase
import com.example.plant_id.data.repository.PlantRepository
import com.example.plant_id.data.repository.WateringLogRepository
import com.example.plant_id.notification.NotificationHelper

/**
 * 浇水提醒后台 Worker
 *
 * 执行逻辑：
 * 1. 从数据库读取所有存活中的植物快照
 * 2. 逐一计算"距上次浇水天数"
 * 3. 若超期（daysSince >= wateringIntervalDays），且今天尚未通知过，则推送通知
 *
 * 去重策略：
 * - 用 SharedPreferences 记录每株植物最后一次通知的日期（yyyy-MM-dd）
 * - 同一天内同一植物只推送一次，防止重复打扰
 */
class WateringReminderWorker(
    private val ctx: Context,
    workerParams: WorkerParameters
) : CoroutineWorker(ctx, workerParams) {

    companion object {
        private const val TAG = "WateringWorker"
        private const val PREFS_KEY = "watering_notif"

        /** 用于调度任务的唯一名称，保证系统中只有一个此任务实例 */
        const val WORK_NAME = "watering_reminder_periodic"
    }

    override suspend fun doWork(): Result {
        val db = PlantDatabase.getInstance(ctx)
        val plantRepository = PlantRepository(db.plantDao())
        val wateringLogRepository = WateringLogRepository(db.wateringLogDao())

        val prefs = ctx.getSharedPreferences(PREFS_KEY, Context.MODE_PRIVATE)
        val todayStr = java.text.SimpleDateFormat("yyyy-MM-dd", java.util.Locale.getDefault())
            .format(java.util.Date())

        val alivePlants = plantRepository.getAllAlivePlantsSnapshot()

        var notifiedCount = 0

        for (plant in alivePlants) {
            val lastWatering = wateringLogRepository.getLastWatering(plant.id)

            // 计算距上次浇水的天数；若从未浇水，则从入手日期算起
            val referenceTime = lastWatering?.wateredAt ?: plant.acquiredDate
            val daysSince = ((System.currentTimeMillis() - referenceTime) / 86_400_000L).toInt()

            // 未超期，跳过
            if (daysSince < plant.wateringIntervalDays) continue

            // 去重：今天是否已经通知过
            val lastNotifiedDay = prefs.getString("notified_${plant.id}", "")
            if (lastNotifiedDay == todayStr) {
                continue
            }

            // 发送通知
            NotificationHelper.sendWateringReminder(ctx, plant, daysSince)
            prefs.edit().putString("notified_${plant.id}", todayStr).apply()
            notifiedCount++
        }

        return Result.success()
    }
}
