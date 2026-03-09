package com.example.plant_id.ui.screens

import android.Manifest
import android.content.pm.PackageManager
import android.net.Uri
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxScope
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import android.app.Application
import androidx.lifecycle.viewmodel.compose.viewModel
import coil.compose.AsyncImage
import com.example.plant_id.data.entity.Photo
import com.example.plant_id.ui.components.NfcSuccessDialog
import com.example.plant_id.ui.components.PlantIllustration
import com.example.plant_id.ui.components.WaterConfirmSheet
import com.example.plant_id.ui.components.WateringSuccessDialog
import com.example.plant_id.ui.components.WateringTimeline
import com.example.plant_id.ui.theme.BtnBg
import com.example.plant_id.ui.theme.CardBg
import com.example.plant_id.ui.theme.CardDivider
import com.example.plant_id.ui.theme.GreenDark
import com.example.plant_id.ui.theme.GreenLight
import com.example.plant_id.ui.theme.MutedColor
import com.example.plant_id.ui.theme.StatusOkBg
import com.example.plant_id.ui.theme.StatusOkColor
import com.example.plant_id.ui.theme.StatusWarnBg
import com.example.plant_id.ui.theme.StatusWarnColor
import com.example.plant_id.ui.theme.TextColor
import com.example.plant_id.ui.viewmodel.NfcViewModel
import com.example.plant_id.ui.viewmodel.PlantDetailViewModel
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

// 植物档案详情页，完整对应原型 plant-detail.html
@Composable
fun PlantDetailScreen(
    plantId: Long,
    onBack: () -> Unit,
    onNavigateToEdit: (plantId: Long) -> Unit = {},
    onNavigateToPhotoTimeline: (plantId: Long) -> Unit = {},
    onArchived: () -> Unit = onBack,
    onDeleted: () -> Unit = onBack,
    nfcVm: NfcViewModel = viewModel()
) {
    val vm: PlantDetailViewModel = viewModel(
        factory = PlantDetailViewModel.factory(LocalContext.current.applicationContext as Application)
    )
    val context = LocalContext.current

    LaunchedEffect(plantId) {
        vm.loadPlant(plantId)
    }

    val plant = vm.plant
    val dateFormatter = remember { SimpleDateFormat("yyyy-MM-dd", Locale.CHINA) }

    var showWaterSheet by remember { mutableStateOf(false) }
    var showArchiveSheet by remember { mutableStateOf(false) }
    var showDeleteSheet by remember { mutableStateOf(false) }

    // 相机拍照状态
    var pendingCameraUri by remember { mutableStateOf<Uri?>(null) }
    var pendingWateringWithPhoto by remember { mutableStateOf(false) }

    val cameraLauncher = rememberLauncherForActivityResult(
        ActivityResultContracts.TakePicture()
    ) { success ->
        val withWatering = pendingWateringWithPhoto
        pendingCameraUri = null
        pendingWateringWithPhoto = false
        if (success) {
            if (withWatering) vm.saveWateringWithPhoto()
            else vm.savePhotoOnly()
        }
        // 取消拍照时不记录浇水也不显示弹窗
    }

    val permissionLauncher = rememberLauncherForActivityResult(
        ActivityResultContracts.RequestPermission()
    ) { granted ->
        if (granted) pendingCameraUri?.let { cameraLauncher.launch(it) }
    }

    // 启动相机（含权限判断）
    fun tryLaunchCamera(withWatering: Boolean) {
        pendingWateringWithPhoto = withWatering
        val uri = vm.prepareCameraUri(context)
        pendingCameraUri = uri
        if (uri == null) {
            if (withWatering) vm.addWatering()
            return
        }
        val hasPermission = context.checkSelfPermission(Manifest.permission.CAMERA) ==
                PackageManager.PERMISSION_GRANTED
        if (hasPermission) cameraLauncher.launch(uri)
        else permissionLauncher.launch(Manifest.permission.CAMERA)
    }

    Box(modifier = Modifier.fillMaxSize()) {

        // ── 主滚动区域 ─────────────────────────────────────────────
        Column(
            modifier = Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
        ) {
            // ── 顶部导航（.hdr 样式） ─────────────────────────────
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .statusBarsPadding()
                    .padding(horizontal = 20.dp, vertical = 16.dp)
            ) {
                // 返回按钮
                DetailCircleButton(
                    onClick = onBack,
                    modifier = Modifier.align(Alignment.CenterStart)
                ) {
                    Icon(
                        imageVector = Icons.AutoMirrored.Filled.ArrowBack,
                        contentDescription = "返回",
                        tint = TextColor,
                        modifier = Modifier.size(18.dp)
                    )
                }
                // 页面标题
                Text(
                    text = "植物档案",
                    fontSize = 15.sp,
                    fontWeight = FontWeight.SemiBold,
                    color = TextColor,
                    modifier = Modifier.align(Alignment.Center)
                )
                // 右侧三点按钮：存活中→终结弹窗，已归档→删除弹窗
                DetailCircleButton(
                    onClick = {
                        if (plant?.status == "archived") showDeleteSheet =
                            true else showArchiveSheet = true
                    },
                    modifier = Modifier.align(Alignment.CenterEnd)
                ) {
                    Column(
                        verticalArrangement = Arrangement.spacedBy(3.5.dp),
                        horizontalAlignment = Alignment.CenterHorizontally
                    ) {
                        repeat(3) {
                            Box(
                                modifier = Modifier
                                    .size(3.5.dp)
                                    .background(TextColor, CircleShape)
                            )
                        }
                    }
                }
            }

            Column(modifier = Modifier.padding(horizontal = 18.dp)) {

                // ── 植物展示主卡片（.hero-card） ──────────────────
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .shadow(
                            elevation = 8.dp,
                            shape = RoundedCornerShape(28.dp),
                            ambientColor = Color(0x478CA578),
                            spotColor = Color(0x288CA578)
                        )
                        .clip(RoundedCornerShape(28.dp))
                        .background(CardBg)
                        .padding(horizontal = 20.dp, vertical = 28.dp),
                    horizontalAlignment = Alignment.CenterHorizontally
                ) {
                    // 植物插图（.ilus 区域，160dp高）
                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(160.dp),
                        contentAlignment = Alignment.Center
                    ) {
                        PlantIllustration(
                            iconName = plant?.iconName ?: "monstera",
                            modifier = Modifier.size(width = 156.dp, height = 180.dp)
                        )
                    }
                    Spacer(modifier = Modifier.height(20.dp))

                    // 植物名称（.hero-name）
                    Text(
                        text = plant?.name ?: "加载中...",
                        fontFamily = FontFamily.Serif,
                        fontSize = 26.sp,
                        fontWeight = FontWeight.Normal,
                        color = TextColor
                    )
                    Spacer(modifier = Modifier.height(4.dp))

                    // 副标题（品种 · 入手日期）
                    val subtitle = plant?.let { p ->
                        buildString {
                            if (p.species.isNotEmpty()) append("${p.species} · ")
                            append("入手于 ${dateFormatter.format(Date(p.acquiredDate))}")
                        }
                    } ?: ""
                    if (subtitle.isNotEmpty()) {
                        Text(text = subtitle, fontSize = 13.sp, color = MutedColor)
                    }
                    Spacer(modifier = Modifier.height(16.dp))

                    // 状态徽章行（.status-row）
                    Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                        // 如果植物已归档，显示固定的"已终结"徽章
                        if (plant?.status == "archived") {
                            StatusBadge(
                                text = "已终结",
                                color = MutedColor,
                                bg = Color(0x1A000000)
                            )
                        } else {
                            // 存活中的植物显示浇水状态徽章
                            val waterInterval = plant?.wateringIntervalDays ?: 7
                            val (badgeText, badgeBg, badgeColor) = when {
                                vm.lastWateredDaysAgo < 0 ->
                                    Triple("尚未浇水", Color(0x1A000000), MutedColor)

                                vm.lastWateredDaysAgo > waterInterval ->
                                    Triple("需要浇水", StatusWarnBg, StatusWarnColor)

                                vm.lastWateredDaysAgo == waterInterval ->
                                    Triple("即将超期", StatusWarnBg, StatusWarnColor)

                                else ->
                                    Triple("状态良好", StatusOkBg, StatusOkColor)
                            }
                            StatusBadge(text = badgeText, color = badgeColor, bg = badgeBg)
                        }

                        // "已养 X 天" 徽章（存活和归档都显示，记录历史）
                        if (vm.daysKept > 0) {
                            StatusBadge(
                                text = "已养 ${vm.daysKept} 天",
                                color = MutedColor,
                                bg = Color(0x1A000000)
                            )
                        }
                    }
                }

                Spacer(modifier = Modifier.height(14.dp))

                //── 一键浇水按钮（仅在存活中显示）────────────────────
                if (plant?.status != "archived") {
                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .shadow(
                                elevation = 8.dp,
                                shape = RoundedCornerShape(16.dp),
                                ambientColor = Color(0x4A3C5A32),
                                spotColor = Color(0x303C5A32)
                            )
                            .clip(RoundedCornerShape(16.dp))
                            .background(Brush.linearGradient(listOf(GreenLight, GreenDark)))
                            .clickable { if (!vm.isAddingWatering) showWaterSheet = true }
                            .padding(vertical = 16.dp),
                        contentAlignment = Alignment.Center
                    ) {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Text(text = "💧", fontSize = 18.sp)
                            Spacer(modifier = Modifier.width(10.dp))
                            Text(
                                text = "一键浇水",
                                fontSize = 16.sp,
                                fontWeight = FontWeight.Bold,
                                color = Color.White,
                                letterSpacing = 0.3.sp
                            )
                        }
                    }

                    Spacer(modifier = Modifier.height(14.dp))
                }

                //──编辑信息按钮（仅在存活中显示）────────────────────
                if (plant?.status != "archived") {
                    SecondaryButton(
                        emoji = "✏️",
                        label = "编辑信息",
                        modifier = Modifier.fillMaxWidth(),
                        onClick = { onNavigateToEdit(plantId) }
                    )

                    Spacer(modifier = Modifier.height(14.dp))
                }

                // ── 基本信息卡片（.info-card） ────────────────────
                DetailInfoCard(title = "基本信息") {
                    val lastWateredText = when (vm.lastWateredDaysAgo) {
                        -1 -> "尚未浇水"
                        0 -> "今天"
                        1 -> "昨天"
                        else -> "${vm.lastWateredDaysAgo} 天前"
                    }
                    DetailInfoRow(emoji = "💧", label = "上次浇水", value = lastWateredText)
                    DetailInfoRow(
                        emoji = "⏱",
                        label = "浇水间隔",
                        value = plant?.let { "每 ${it.wateringIntervalDays} 天" } ?: "—"
                    )
                    DetailInfoRow(
                        emoji = "📅",
                        label = "入手日期",
                        value = plant?.let { dateFormatter.format(Date(it.acquiredDate)) } ?: "—"
                    )
                    // 结束日期（仅归档时显示）
                    plant?.archivedAt?.let { archivedAt ->
                        DetailInfoRow(
                            emoji = "🏁",
                            label = "结束日期",
                            value = dateFormatter.format(Date(archivedAt))
                        )
                    }
                    DetailInfoRow(
                        emoji = "📡",
                        label = "NFC 标签",
                        value = plant?.let {
                            if (it.nfcTagId.isEmpty()) "未绑定" else it.nfcTagId
                        } ?: "—",
                        isLast = true
                    )
                }

                Spacer(modifier = Modifier.height(14.dp))

                // ── 养护备注卡片（仅有内容时展示） ────────────────
                val notesText = plant?.notes.orEmpty()
                if (notesText.isNotBlank()) {
                    DetailInfoCard(title = "养护备注") {
                        Text(
                            text = notesText,
                            fontSize = 14.sp,
                            color = TextColor,
                            lineHeight = 22.sp
                        )
                    }
                    Spacer(modifier = Modifier.height(14.dp))
                }

                // ── 浇水记录卡片 ──────────────────────────────────
                DetailInfoCard(title = "浇水记录") {
                    WateringTimeline(logs = vm.wateringLogs)
                }

                Spacer(modifier = Modifier.height(14.dp))

                // ── 最新照片卡片（占位，阶段九实现） ──────────────
                DetailInfoCard(title = "最新照片") {
                    PhotoGrid(
                        photos = vm.photos,
                        onTakePhoto = { tryLaunchCamera(withWatering = false) },
                        onViewAll = { onNavigateToPhotoTimeline(plantId) }
                    )
                }

                Spacer(modifier = Modifier.height(14.dp))

                // ── 终结/删除档案按钮 ────────────────────────────
                val isArchived = plant?.status == "archived"
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clip(RoundedCornerShape(14.dp))
                        .background(Color(0x14C85050))
                        .border(1.5.dp, Color(0x40C05050), RoundedCornerShape(14.dp))
                        .clickable {
                            if (isArchived) showDeleteSheet = true else showArchiveSheet = true
                        }
                        .padding(vertical = 13.dp),
                    contentAlignment = Alignment.Center
                ) {
                    Text(
                        text = if (isArchived) "删除档案" else "终结档案",
                        fontSize = 13.sp,
                        fontWeight = FontWeight.SemiBold,
                        color = Color(0xFFC05050)
                    )
                }

                Spacer(modifier = Modifier.height(32.dp))
            }
        }

        // ── 浇水确认弹窗 ──────────────────────────────────────────
        if (showWaterSheet) {
            WaterConfirmSheet(
                plantName = plant?.name ?: "",
                onDismiss = { showWaterSheet = false },
                onWaterOnly = {
                    showWaterSheet = false
                    vm.addWatering()
                },
                onWaterAndPhoto = {
                    showWaterSheet = false
                    tryLaunchCamera(withWatering = true)
                }
            )
        }

        // ── 终结档案确认弹窗 ──────────────────────────────────────
        if (showArchiveSheet) {
            DetailArchiveSheet(
                onDismiss = { showArchiveSheet = false },
                onConfirm = {
                    showArchiveSheet = false
                    vm.archivePlant(onArchived)
                }
            )
        }

        // ── 删除档案确认弹窗 ──────────────────────────────────────
        if (showDeleteSheet) {
            DetailDeleteSheet(
                onDismiss = { showDeleteSheet = false },
                onConfirm = {
                    showDeleteSheet = false
                    vm.deletePlant(onDeleted)
                }
            )
        }

        // ── 浇水成功弹窗 ──────────────────────────────────────────────
        if (vm.showWateringSuccess) {
            val plantName = plant?.name ?: ""
            val wateringInterval = plant?.wateringIntervalDays ?: 7
            // 计算下次浇水日期
            val nextWateringDate = remember {
                val calendar = java.util.Calendar.getInstance()
                calendar.add(java.util.Calendar.DAY_OF_YEAR, wateringInterval)
                SimpleDateFormat("yyyy 年 M 月 d 日", Locale.CHINA).format(calendar.time)
            }
            WateringSuccessDialog(
                plantName = plantName,
                nextWateringDate = nextWateringDate,
                onDismiss = { vm.dismissWateringSuccess() }
            )
        }

        // NFC 成功导入弹窗（置于最顶层，覆盖所有内容）
        NfcSuccessDialog(
            isVisible = nfcVm.showNfcSuccessDialog,
            onDismiss = { nfcVm.hideSuccessDialog() }
        )
    }
}

// ── 私有组件 ──────────────────────────────────────────────────────

// 圆形图标按钮（对应原型 .hbtn）
@Composable
private fun DetailCircleButton(
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    content: @Composable BoxScope.() -> Unit
) {
    Box(
        modifier = modifier
            .size(40.dp)
            .shadow(
                6.dp,
                CircleShape,
                ambientColor = Color(0x388CA578),
                spotColor = Color(0x288CA578)
            )
            .clip(CircleShape)
            .background(CardBg)
            .clickable(onClick = onClick),
        contentAlignment = Alignment.Center,
        content = content
    )
}

// 状态徽章（.badge）
@Composable
private fun StatusBadge(text: String, color: Color, bg: Color) {
    Box(
        modifier = Modifier
            .clip(RoundedCornerShape(50.dp))
            .background(bg)
            .padding(horizontal = 14.dp, vertical = 6.dp)
    ) {
        Text(text = text, fontSize = 12.sp, fontWeight = FontWeight.SemiBold, color = color)
    }
}

// 次要操作按钮（.sec-btn）
@Composable
private fun SecondaryButton(
    emoji: String,
    label: String,
    modifier: Modifier = Modifier,
    onClick: () -> Unit = {}
) {
    Box(
        modifier = modifier
            .shadow(
                6.dp,
                RoundedCornerShape(14.dp),
                ambientColor = Color(0x388CA578),
                spotColor = Color(0x288CA578)
            )
            .clip(RoundedCornerShape(14.dp))
            .background(CardBg)
            .clickable(onClick = onClick)
            .padding(vertical = 13.dp),
        contentAlignment = Alignment.Center
    ) {
        Row(
            horizontalArrangement = Arrangement.Center,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(text = emoji, fontSize = 14.sp)
            Spacer(modifier = Modifier.width(7.dp))
            Text(
                text = label,
                fontSize = 13.sp,
                fontWeight = FontWeight.SemiBold,
                color = GreenDark
            )
        }
    }
}

// 信息卡片容器（.info-card）
@Composable
private fun DetailInfoCard(
    title: String,
    content: @Composable ColumnScope.() -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .shadow(
                6.dp,
                RoundedCornerShape(24.dp),
                ambientColor = Color(0x388CA578),
                spotColor = Color(0x288CA578)
            )
            .clip(RoundedCornerShape(24.dp))
            .background(CardBg)
            .padding(20.dp)
    ) {
        Text(
            text = title.uppercase(),
            fontSize = 12.sp,
            fontWeight = FontWeight.Bold,
            color = MutedColor,
            letterSpacing = 0.8.sp
        )
        Spacer(modifier = Modifier.height(14.dp))
        content()
    }
}

// 信息行（.info-row）
@Composable
private fun DetailInfoRow(
    emoji: String,
    label: String,
    value: String,
    isLast: Boolean = false
) {
    Column {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(vertical = 11.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // 左侧：icon + label 固定宽度容器（确保对齐）
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(12.dp),
                modifier = Modifier
                    .width(140.dp)
            ) {
                Box(
                    modifier = Modifier.size(24.dp),
                    contentAlignment = Alignment.Center
                ) {
                    Text(text = emoji, fontSize = 16.sp)
                }
                Text(text = label, fontSize = 14.sp, color = MutedColor)
            }
            // 右侧：数值右对齐
            Text(
                text = value,
                fontSize = 14.sp,
                fontWeight = FontWeight.SemiBold,
                color = TextColor,
                modifier = Modifier.weight(1f),
                textAlign = androidx.compose.ui.text.style.TextAlign.End
            )
        }
        if (!isLast) {
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(1.dp)
                    .background(CardDivider)
            )
        }
    }
}

// 照片网格：展示最新照片缩略图（至多 5 张）+ 拍照按鈕，底部有“查看全部”链接
@Composable
private fun PhotoGrid(
    photos: List<Photo>,
    onTakePhoto: () -> Unit,
    onViewAll: () -> Unit
) {
    // 取最新 5 张，加上“+”按鈕，共 6 个位置（ 3 x 2 网格）
    val displayPhotos = photos.take(5)
    val allItems: List<Photo?> = displayPhotos + listOf(null) // null = 拍照按鈕

    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
        allItems.chunked(3).forEach { rowItems ->
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                rowItems.forEach { photo ->
                    if (photo != null) {
                        // 真实照片缩略图
                        Box(
                            modifier = Modifier
                                .weight(1f)
                                .aspectRatio(1f)
                                .clip(RoundedCornerShape(12.dp))
                        ) {
                            AsyncImage(
                                model = photo.filePath,
                                contentDescription = null,
                                contentScale = ContentScale.Crop,
                                modifier = Modifier.fillMaxSize()
                            )
                        }
                    } else {
                        // 拍照按鈕（虚线边框）
                        Box(
                            modifier = Modifier
                                .weight(1f)
                                .aspectRatio(1f)
                                .clip(RoundedCornerShape(12.dp))
                                .background(BtnBg)
                                .border(2.dp, Color(0x408CA550), RoundedCornerShape(12.dp))
                                .clickable(onClick = onTakePhoto),
                            contentAlignment = Alignment.Center
                        ) {
                            Text(text = "📷", fontSize = 20.sp)
                        }
                    }
                }
                // 最后一行不足 3 个时补空白占位
                repeat(3 - rowItems.size) {
                    Spacer(modifier = Modifier.weight(1f))
                }
            }
        }

        // 查看全部链接（有照片时才展示）
        if (photos.isNotEmpty()) {
            Spacer(modifier = Modifier.height(8.dp))
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .clickable(onClick = onViewAll)
                    .padding(vertical = 4.dp),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = "查看全部 ${photos.size} 张照片 →",
                    fontSize = 13.sp,
                    fontWeight = FontWeight.SemiBold,
                    color = GreenDark
                )
            }
        }
    }
}

// 终结档案确认底部弹窗（对应原型 #endModal）
@Composable
private fun DetailArchiveSheet(
    onDismiss: () -> Unit,
    onConfirm: () -> Unit
) {
    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(Color(0x73000000))
            .clickable(onClick = onDismiss)
    ) {
        Column(
            modifier = Modifier
                .align(Alignment.BottomCenter)
                .fillMaxWidth()
                .clip(RoundedCornerShape(topStart = 28.dp, topEnd = 28.dp))
                .background(CardBg)
                .clickable(enabled = false) {}
                .padding(horizontal = 20.dp)
                .padding(top = 24.dp, bottom = 32.dp)
        ) {
            Text(
                text = "终结档案",
                fontFamily = FontFamily.Serif,
                fontSize = 20.sp,
                fontWeight = FontWeight.Normal,
                color = TextColor
            )
            Spacer(modifier = Modifier.height(6.dp))
            Text(
                text = "档案将永久归档，NFC 标签可重新绑定新植物。",
                fontSize = 13.sp,
                color = MutedColor,
                lineHeight = 18.sp
            )
            Spacer(modifier = Modifier.height(20.dp))

            // 确认终结（红色危险按钮）
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(14.dp))
                    .background(Color(0x1AC85050))
                    .clickable(onClick = onConfirm)
                    .padding(vertical = 14.dp),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = "确认终结",
                    fontSize = 15.sp,
                    fontWeight = FontWeight.SemiBold,
                    color = Color(0xFFC05050)
                )
            }
            Spacer(modifier = Modifier.height(10.dp))

            // 取消
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(14.dp))
                    .background(BtnBg)
                    .clickable(onClick = onDismiss)
                    .padding(vertical = 14.dp),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = "取消",
                    fontSize = 15.sp,
                    fontWeight = FontWeight.SemiBold,
                    color = MutedColor
                )
            }
        }
    }
}

// 删除档案确认底部弹窗
@Composable
private fun DetailDeleteSheet(
    onDismiss: () -> Unit,
    onConfirm: () -> Unit
) {
    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(Color(0x73000000))
            .clickable(onClick = onDismiss)
    ) {
        Column(
            modifier = Modifier
                .align(Alignment.BottomCenter)
                .fillMaxWidth()
                .clip(RoundedCornerShape(topStart = 28.dp, topEnd = 28.dp))
                .background(CardBg)
                .clickable(enabled = false) {}
                .padding(horizontal = 20.dp)
                .padding(top = 24.dp, bottom = 32.dp)
        ) {
            Text(
                text = "删除档案",
                fontFamily = FontFamily.Serif,
                fontSize = 20.sp,
                fontWeight = FontWeight.Normal,
                color = TextColor
            )
            Spacer(modifier = Modifier.height(6.dp))
            Text(
                text = "档案将彻底删除，所有记录无法恢复。",
                fontSize = 13.sp,
                color = MutedColor,
                lineHeight = 18.sp
            )
            Spacer(modifier = Modifier.height(20.dp))

            // 确认删除（红色危险按钮）
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(14.dp))
                    .background(Color(0x1AC85050))
                    .clickable(onClick = onConfirm)
                    .padding(vertical = 14.dp),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = "确认删除",
                    fontSize = 15.sp,
                    fontWeight = FontWeight.SemiBold,
                    color = Color(0xFFC05050)
                )
            }
            Spacer(modifier = Modifier.height(10.dp))

            // 取消
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(14.dp))
                    .background(BtnBg)
                    .clickable(onClick = onDismiss)
                    .padding(vertical = 14.dp),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = "取消",
                    fontSize = 15.sp,
                    fontWeight = FontWeight.SemiBold,
                    color = MutedColor
                )
            }
        }
    }
}


