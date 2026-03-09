package com.example.plant_id.ui.screens

import android.Manifest
import android.content.pm.PackageManager
import android.net.Uri
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
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
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import android.app.Application
import androidx.lifecycle.viewmodel.compose.viewModel
import coil.compose.AsyncImage
import com.example.plant_id.data.entity.Photo
import com.example.plant_id.ui.theme.CardBg
import com.example.plant_id.ui.theme.GreenDark
import com.example.plant_id.ui.theme.MutedColor
import com.example.plant_id.ui.theme.TextColor
import com.example.plant_id.ui.viewmodel.PlantDetailViewModel
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Locale

// 照片时间线页面，完整对应原型 photo-timeline.html
@Composable
fun PhotoTimelineScreen(
    plantId: Long,
    onBack: () -> Unit
) {
    val vm: PlantDetailViewModel = viewModel(
        factory = PlantDetailViewModel.factory(LocalContext.current.applicationContext as Application)
    )
    LaunchedEffect(plantId) { vm.loadPlant(plantId) }

    val plant = vm.plant
    val photos = vm.photos
    val wateringLogs = vm.wateringLogs

    // 浇水时拍摄的照片路径集合（用于过滤和来源徽章）
    val wateringPhotoPaths = remember(wateringLogs) {
        wateringLogs.map { it.photoPath }.filter { it.isNotBlank() }.toSet()
    }

    var filterType by remember { mutableStateOf("all") }

    val filteredPhotos = remember(photos, filterType, wateringPhotoPaths) {
        when (filterType) {
            "watering" -> photos.filter { it.filePath in wateringPhotoPaths }
            "manual" -> photos.filter { it.filePath !in wateringPhotoPaths }
            else -> photos
        }
    }

    // 按月份分组，保持时间倒序
    val groupedByMonth: List<Pair<String, List<Photo>>> = remember(filteredPhotos) {
        filteredPhotos
            .groupBy { photo ->
                val cal = Calendar.getInstance()
                cal.timeInMillis = photo.takenAt
                "${cal.get(Calendar.YEAR)} 年 ${cal.get(Calendar.MONTH) + 1} 月"
            }
            .entries
            .sortedByDescending { (_, list) -> list.first().takenAt }
            .map { (month, list) -> month to list }
    }

    // 灯箱状态（null = 关闭，非 null = 展示对应照片）
    var lightboxPhoto by remember { mutableStateOf<Photo?>(null) }

    // 相机相关状态
    val context = LocalContext.current
    var pendingCameraUri by remember { mutableStateOf<Uri?>(null) }

    val cameraLauncher = rememberLauncherForActivityResult(
        ActivityResultContracts.TakePicture()
    ) { success ->
        pendingCameraUri = null
        if (success) vm.savePhotoOnly()
    }

    val permissionLauncher = rememberLauncherForActivityResult(
        ActivityResultContracts.RequestPermission()
    ) { granted ->
        if (granted) pendingCameraUri?.let { cameraLauncher.launch(it) }
    }

    fun takePicture() {
        val uri = vm.prepareCameraUri(context) ?: return
        pendingCameraUri = uri
        val hasPermission = context.checkSelfPermission(Manifest.permission.CAMERA) ==
                PackageManager.PERMISSION_GRANTED
        if (hasPermission) cameraLauncher.launch(uri)
        else permissionLauncher.launch(Manifest.permission.CAMERA)
    }

    Box(modifier = Modifier.fillMaxSize()) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
        ) {
            // ── 顶部导航栏 ───────────────────────────────────────────
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .statusBarsPadding()
                    .padding(horizontal = 18.dp, vertical = 16.dp),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                // 返回按钮
                Box(
                    modifier = Modifier
                        .size(40.dp)
                        .shadow(
                            6.dp, CircleShape,
                            ambientColor = Color(0x388CA578), spotColor = Color(0x288CA578)
                        )
                        .clip(CircleShape)
                        .background(CardBg)
                        .clickable(onClick = onBack),
                    contentAlignment = Alignment.Center
                ) {
                    Icon(
                        imageVector = Icons.AutoMirrored.Filled.ArrowBack,
                        contentDescription = "返回",
                        tint = TextColor,
                        modifier = Modifier.size(18.dp)
                    )
                }
                Text(
                    text = "${plant?.name ?: ""} · 照片记录",
                    fontSize = 15.sp,
                    fontWeight = FontWeight.SemiBold,
                    color = TextColor
                )
                // 拍照按钮
                Box(
                    modifier = Modifier
                        .size(40.dp)
                        .shadow(
                            6.dp, CircleShape,
                            ambientColor = Color(0x388CA578), spotColor = Color(0x288CA578)
                        )
                        .clip(CircleShape)
                        .background(CardBg)
                        .clickable { takePicture() },
                    contentAlignment = Alignment.Center
                ) {
                    Text(text = "📷", fontSize = 18.sp)
                }
            }

            Column(modifier = Modifier.padding(horizontal = 18.dp)) {

                // ── 页面标题 ─────────────────────────────────────────
                Text(
                    text = "成长记录",
                    fontFamily = FontFamily.Serif,
                    fontSize = 26.sp,
                    fontWeight = FontWeight.Normal,
                    color = TextColor
                )
                Spacer(modifier = Modifier.height(18.dp))

                // ── 统计条 ───────────────────────────────────────────
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(10.dp)
                ) {
                    TimelineStatCard(
                        value = photos.size.toString(),
                        label = "张照片",
                        modifier = Modifier.weight(1f)
                    )
                    TimelineStatCard(
                        value = vm.daysKept.toString(),
                        label = "养护天数",
                        modifier = Modifier.weight(1f)
                    )
                    TimelineStatCard(
                        value = wateringLogs.size.toString(),
                        label = "次浇水",
                        modifier = Modifier.weight(1f)
                    )
                }
                Spacer(modifier = Modifier.height(20.dp))

                // ── 滤镜栏 ───────────────────────────────────────────
                Row(
                    modifier = Modifier.horizontalScroll(rememberScrollState()),
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    TimelineFilterButton("全部", filterType == "all") { filterType = "all" }
                    TimelineFilterButton("浇水时", filterType == "watering") {
                        filterType = "watering"
                    }
                    TimelineFilterButton("手动拍摄", filterType == "manual") {
                        filterType = "manual"
                    }
                }
                Spacer(modifier = Modifier.height(20.dp))

                // ── 照片列表（或空状态） ──────────────────────────────
                if (filteredPhotos.isEmpty()) {
                    // 空状态卡片
                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(160.dp)
                            .shadow(
                                6.dp, RoundedCornerShape(16.dp),
                                ambientColor = Color(0x288CA578), spotColor = Color(0x188CA578)
                            )
                            .clip(RoundedCornerShape(16.dp))
                            .background(CardBg),
                        contentAlignment = Alignment.Center
                    ) {
                        Column(horizontalAlignment = Alignment.CenterHorizontally) {
                            Text(text = "📷", fontSize = 32.sp)
                            Spacer(modifier = Modifier.height(10.dp))
                            Text(
                                text = "还没有照片",
                                fontSize = 15.sp,
                                fontWeight = FontWeight.SemiBold,
                                color = TextColor
                            )
                            Spacer(modifier = Modifier.height(4.dp))
                            Text(
                                text = "浇水时拍照或点击右上角拍照",
                                fontSize = 12.sp,
                                color = MutedColor
                            )
                        }
                    }
                } else {
                    groupedByMonth.forEach { (month, monthPhotos) ->
                        // 月份标题行
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Text(
                                text = month,
                                fontSize = 12.sp,
                                fontWeight = FontWeight.Bold,
                                color = MutedColor
                            )
                            Spacer(modifier = Modifier.width(8.dp))
                            Box(
                                modifier = Modifier
                                    .weight(1f)
                                    .height(1.dp)
                                    .background(Color(0x1A000000))
                            )
                        }
                        Spacer(modifier = Modifier.height(12.dp))

                        // 该月照片卡片
                        monthPhotos.forEach { photo ->
                            TimelinePhotoCard(
                                photo = photo,
                                isWateringPhoto = photo.filePath in wateringPhotoPaths,
                                onClick = { lightboxPhoto = photo }
                            )
                            Spacer(modifier = Modifier.height(12.dp))
                        }
                        Spacer(modifier = Modifier.height(12.dp))
                    }
                }

                Spacer(modifier = Modifier.height(80.dp))
            }
        }

        // ── 灯箱（全屏查看） ─────────────────────────────────────────
        lightboxPhoto?.let { photo ->
            PhotoLightbox(
                photo = photo,
                isWateringPhoto = photo.filePath in wateringPhotoPaths,
                onDismiss = { lightboxPhoto = null }
            )
        }
    }
}

// 统计数字卡片（对应原型 .stat）
@Composable
private fun TimelineStatCard(
    value: String,
    label: String,
    modifier: Modifier = Modifier
) {
    Box(
        modifier = modifier
            .shadow(
                6.dp, RoundedCornerShape(16.dp),
                ambientColor = Color(0x388CA578), spotColor = Color(0x288CA578)
            )
            .clip(RoundedCornerShape(16.dp))
            .background(CardBg)
            .padding(vertical = 14.dp),
        contentAlignment = Alignment.Center
    ) {
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            Text(
                text = value,
                fontSize = 22.sp,
                fontWeight = FontWeight.Bold,
                color = GreenDark
            )
            Spacer(modifier = Modifier.height(3.dp))
            Text(text = label, fontSize = 11.sp, color = MutedColor)
        }
    }
}

// 滤镜选择按钮（对应原型 .fb）
@Composable
private fun TimelineFilterButton(
    text: String,
    selected: Boolean,
    onClick: () -> Unit
) {
    Box(
        modifier = Modifier
            .shadow(
                elevation = if (selected) 4.dp else 2.dp,
                shape = RoundedCornerShape(50.dp),
                ambientColor = if (selected) Color(0x4C3D5C33) else Color(0x188CA578),
                spotColor = if (selected) Color(0x4C3D5C33) else Color(0x188CA578)
            )
            .clip(RoundedCornerShape(50.dp))
            .background(if (selected) GreenDark else CardBg)
            .clickable(onClick = onClick)
            .padding(horizontal = 14.dp, vertical = 7.dp)
    ) {
        Text(
            text = text,
            fontSize = 12.sp,
            fontWeight = FontWeight.SemiBold,
            color = if (selected) Color.White else MutedColor
        )
    }
}

// 照片卡片（对应原型 .photo-card）
@Composable
private fun TimelinePhotoCard(
    photo: Photo,
    isWateringPhoto: Boolean,
    onClick: () -> Unit
) {
    val dateFormatter = remember { SimpleDateFormat("M月d日  HH:mm", Locale.CHINA) }

    Box(
        modifier = Modifier
            .fillMaxWidth()
            .shadow(
                8.dp, RoundedCornerShape(20.dp),
                ambientColor = Color(0x388CA578), spotColor = Color(0x288CA578)
            )
            .clip(RoundedCornerShape(20.dp))
            .background(CardBg)
            .clickable(onClick = onClick)
    ) {
        Column {
            // 照片缩略图
            AsyncImage(
                model = photo.filePath,
                contentDescription = null,
                contentScale = ContentScale.Crop,
                modifier = Modifier
                    .fillMaxWidth()
                    .height(200.dp)
            )
            // 元数据行
            Column(modifier = Modifier.padding(14.dp)) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = dateFormatter.format(java.util.Date(photo.takenAt)),
                        fontSize = 13.sp,
                        fontWeight = FontWeight.Bold,
                        color = TextColor
                    )
                    // 来源徽章（对应原型 .pm-src）
                    Box(
                        modifier = Modifier
                            .clip(RoundedCornerShape(50.dp))
                            .background(
                                if (isWateringPhoto) Color(0x1E3D5C33) else Color(0x1AB47832)
                            )
                            .padding(horizontal = 10.dp, vertical = 4.dp)
                    ) {
                        Text(
                            text = if (isWateringPhoto) "💧 浇水时拍摄" else "📷 手动拍摄",
                            fontSize = 11.sp,
                            fontWeight = FontWeight.SemiBold,
                            color = if (isWateringPhoto) GreenDark else Color(0xFFA07015)
                        )
                    }
                }
                if (photo.note.isNotBlank()) {
                    Spacer(modifier = Modifier.height(6.dp))
                    Text(
                        text = photo.note,
                        fontSize = 13.sp,
                        color = MutedColor,
                        fontStyle = FontStyle.Italic
                    )
                }
            }
        }
    }
}

// 全屏灯箱（对应原型 .lightbox）
@Composable
private fun PhotoLightbox(
    photo: Photo,
    isWateringPhoto: Boolean,
    onDismiss: () -> Unit
) {
    val dateFormatter = remember { SimpleDateFormat("yyyy-MM-dd  HH:mm", Locale.CHINA) }

    Dialog(
        onDismissRequest = onDismiss,
        properties = DialogProperties(usePlatformDefaultWidth = false)
    ) {
        Box(
            modifier = Modifier
                .fillMaxSize()
                .background(Color(0xEE000000))
                .clickable(onClick = onDismiss),
            contentAlignment = Alignment.Center
        ) {
            Column(
                modifier = Modifier.padding(20.dp),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                // 关闭按钮（右对齐）
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.End
                ) {
                    Box(
                        modifier = Modifier
                            .size(40.dp)
                            .clip(CircleShape)
                            .background(Color(0x26FFFFFF))
                            .clickable(onClick = onDismiss),
                        contentAlignment = Alignment.Center
                    ) {
                        Text(text = "✕", fontSize = 16.sp, color = Color.White)
                    }
                }
                Spacer(modifier = Modifier.height(12.dp))

                // 大图
                AsyncImage(
                    model = photo.filePath,
                    contentDescription = null,
                    contentScale = ContentScale.Fit,
                    modifier = Modifier
                        .fillMaxWidth()
                        .clip(RoundedCornerShape(16.dp))
                )
                Spacer(modifier = Modifier.height(18.dp))

                // 日期
                Text(
                    text = dateFormatter.format(java.util.Date(photo.takenAt)),
                    fontSize = 14.sp,
                    fontWeight = FontWeight.SemiBold,
                    color = Color.White
                )
                // 备注（可选）
                if (photo.note.isNotBlank()) {
                    Spacer(modifier = Modifier.height(6.dp))
                    Text(
                        text = photo.note,
                        fontSize = 13.sp,
                        color = Color(0xAAFFFFFF)
                    )
                }
            }
        }
    }
}
