package com.example.plant_id

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.nfc.NfcAdapter
import android.os.Build
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.activity.result.contract.ActivityResultContracts
import androidx.lifecycle.ViewModelProvider
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import com.example.plant_id.nfc.NfcReader
import com.example.plant_id.notification.NotificationHelper
import com.example.plant_id.notification.NotificationHelper.EXTRA_PLANT_ID
import com.example.plant_id.ui.navigation.MainNavigation
import com.example.plant_id.ui.theme.PlantidTheme
import com.example.plant_id.ui.viewmodel.NfcViewModel
import com.example.plant_id.worker.WateringReminderWorker
import java.util.Calendar
import java.util.concurrent.TimeUnit

class MainActivity : ComponentActivity() {

    // NFC 适配器，设备无 NFC 时为 null
    private var nfcAdapter: NfcAdapter? = null

    // NFC ViewModel：由 Activity 写入，Compose 侧读取并导航
    private lateinit var nfcViewModel: NfcViewModel

    // Android 13+ 运行时通知权限申请回调
    private val notifPermissionLauncher =
        registerForActivityResult(ActivityResultContracts.RequestPermission()) { granted ->
            if (granted) {
                scheduleWateringReminder()
            }
        }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // 初始化 NFC 适配器和 ViewModel
        nfcAdapter = NfcAdapter.getDefaultAdapter(this)
        nfcViewModel = ViewModelProvider(this, NfcViewModel.factory(application))[NfcViewModel::class.java]

        enableEdgeToEdge()

        // 初始化通知渠道（Android 8.0+ 必须）
        NotificationHelper.createChannel(this)

        // 申请通知权限（Android 13+ 需要动态申请）
        requestNotificationPermissionAndSchedule()

        // 先建立 Compose UI 管道，再处理冷启动 Intent
        // 这样 LaunchedEffect 的 snapshotFlow 收集器能在 DB 查询完成前就就位，不会遗漏事件
        setContent {
            PlantidTheme {
                MainNavigation()
            }
        }

        // 处理"应用被 NFC 冷启动"的情况（必须在 setContent 之后）
        handleNfcIntent(intent)

        // 处理来自通知的深链接（冷启动）
        handleNotificationIntent(intent)
    }

    override fun onResume() {
        super.onResume()
        enableNfcReaderMode()
    }

    override fun onPause() {
        super.onPause()
        // 页面进入后台时停止读卡，避免泄露资源
        try {
            nfcAdapter?.disableReaderMode(this)
        } catch (e: SecurityException) {
            // 某些设备 NFC 权限检查更严格，静默忽略
        }
    }

    // Activity 处于前台时触碰 NFC 标签，系统通过此方法送入新 Intent
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleNfcIntent(intent)
        handleNotificationIntent(intent)  // 热启动时也需处理开锁深链接
    }

    // 解析 NFC Intent 并交给 ViewModel 处理
    private fun handleNfcIntent(intent: Intent) {
        val tagId = NfcReader.readTagId(intent) ?: return
        nfcViewModel.processTag(tagId)
    }

    /**
     * 处理通知深链接
     * 点击浏水提醒通知将会带着 plant_id extra 打开 MainActivity。
     * 这里读取并调用 NfcViewModel.navigateToPlant() 转进漏水详情页
     */
    private fun handleNotificationIntent(intent: Intent?) {
        val plantId = intent?.getLongExtra(EXTRA_PLANT_ID, -1L) ?: -1L
        if (plantId > 0L) {
            nfcViewModel.navigateToPlant(plantId)
        }
    }

    /**
     * 申请通知权限（Android 13+）并调度 WorkManager 周期任务
     * - 若已授权，直接调度
     * - 若未授权，向用户申请权限，回调成功后再调度
     */
    private fun requestNotificationPermissionAndSchedule() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            if (checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS)
                == PackageManager.PERMISSION_GRANTED
            ) {
                scheduleWateringReminder()
            } else {
                notifPermissionLauncher.launch(Manifest.permission.POST_NOTIFICATIONS)
            }
        } else {
            // Android 12 及以下无需动态权限
            scheduleWateringReminder()
        }
    }

    /**
     * 使用 WorkManager 调度每日24小时的周期提醒任务
     * - 首次执行时间：计算距明早 8:00 的将来时刻所需的延迟
     * - 策略 KEEP：如果任务已存在，保持现有的，不重复创建
     */
    private fun scheduleWateringReminder() {
        val delayMs = calculateDelayToNextEightAM()
        val workRequest = PeriodicWorkRequestBuilder<WateringReminderWorker>(24, TimeUnit.HOURS)
            .setInitialDelay(delayMs, TimeUnit.MILLISECONDS)
            .build()
        WorkManager.getInstance(this).enqueueUniquePeriodicWork(
            WateringReminderWorker.WORK_NAME,
            ExistingPeriodicWorkPolicy.KEEP,
            workRequest
        )
    }

    /**
     * 计算当前时刻到明早 8:00 的毫秒延迟
     * 若今日 8:00 已过，返回到明日 8:00 的延迟
     */
    private fun calculateDelayToNextEightAM(): Long {
        val now = Calendar.getInstance()
        val nextEightAM = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, 8)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
            if (!after(now)) add(Calendar.DATE, 1)  // 今日8点已过，延到明日
        }
        return nextEightAM.timeInMillis - now.timeInMillis
    }

    // 启用 NFC ReaderMode：底层直接回调，绕过 OEM 系统 NFC 服务拦截
    // 兼容所有 Android 设备（包括小米 MIUI、华为 EMUI 等国产 ROM）
    private fun enableNfcReaderMode() {
        val adapter = nfcAdapter ?: return
        if (!adapter.isEnabled) return
        try {
            // 注意：不加 FLAG_READER_SKIP_NDEF_CHECK，保留 NDEF 能力，以支持 AAR 写入
            val flags = NfcAdapter.FLAG_READER_NFC_A or
                    NfcAdapter.FLAG_READER_NFC_B or
                    NfcAdapter.FLAG_READER_NFC_F or
                    NfcAdapter.FLAG_READER_NFC_V
            adapter.enableReaderMode(this, NfcAdapter.ReaderCallback { tag ->
                // 回调在后台线程（NFC 线程）：同步执行，不要跨线程操作 Tag 对象
                val tagId = NfcReader.readTagId(tag)
                // 仅对已绑定标签写入 URI+AAR（激活冷启动能力）；未绑定标签不写入
                // isTagBound() 读取 @Volatile 缓存，NFC 线程安全
                if (nfcViewModel.isTagBound(tagId)) {
                    NfcReader.writeAar(tag, packageName)
                }
                runOnUiThread {
                    nfcViewModel.processTag(tagId)
                }
            }, flags, null)
        } catch (e: SecurityException) {
            // 某些设备 NFC 权限检查更严格，静默忽略（优雅降级）
        }
    }
}
