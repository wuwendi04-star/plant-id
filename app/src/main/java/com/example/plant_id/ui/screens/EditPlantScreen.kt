package com.example.plant_id.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Delete
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
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import android.app.Application
import androidx.compose.ui.platform.LocalContext
import androidx.lifecycle.viewmodel.compose.viewModel
import com.example.plant_id.ui.components.DatePickerField
import com.example.plant_id.ui.components.FormActionButtons
import com.example.plant_id.ui.components.FormCard
import com.example.plant_id.ui.components.FormFieldGroup
import com.example.plant_id.ui.components.FormFieldGroupLast
import com.example.plant_id.ui.components.FormLabel
import com.example.plant_id.ui.components.FormSectionHeader
import com.example.plant_id.ui.components.FormTextArea
import com.example.plant_id.ui.components.FormTextField
import com.example.plant_id.ui.components.FormTopBar
import com.example.plant_id.ui.components.IconSelector
import com.example.plant_id.ui.components.WateringIntervalPicker
import com.example.plant_id.ui.navigation.screenTopPadding
import com.example.plant_id.ui.theme.BtnBg
import com.example.plant_id.ui.theme.CardBg
import com.example.plant_id.ui.theme.GreenDark
import com.example.plant_id.ui.theme.GreenLightBg
import com.example.plant_id.ui.theme.MutedColor
import com.example.plant_id.ui.theme.TextColor
import com.example.plant_id.ui.viewmodel.CreatePlantViewModel

/**
 * 编辑植物档案页面（对应原型 edit-plant.html）
 * 包含：图标选择 / 基本信息 / 养护设置（含状态胶囊） / 危险区域 / 终结确认底部弹窗
 *
 * @param plantId       要编辑的植物 ID
 * @param onBack        返回 / 取消回调
 * @param onSaved       保存成功后回调
 * @param onArchived    终结归档后回调（通常需要弹出到首页）
 */
@Composable
fun EditPlantScreen(
    plantId: Long,
    onBack: () -> Unit,
    onSaved: () -> Unit = onBack,
    onArchived: () -> Unit = onBack
) {
    val vm: CreatePlantViewModel = viewModel(
        factory = CreatePlantViewModel.factory(LocalContext.current.applicationContext as Application)
    )

    // 加载已有数据（编辑模式）
    LaunchedEffect(plantId) {
        vm.loadPlant(plantId)
    }

    // 名称校验错误状态
    var showNameError by remember { mutableStateOf(false) }
    var showSpeciesError by remember { mutableStateOf(false) }

    // 终结确认底部弹窗开关
    var showArchiveSheet by remember { mutableStateOf(false) }

    // ── 根容器（Box 用于叠加底部弹窗） ──────────────────────────
    Box(modifier = Modifier.fillMaxSize()) {

        // ── 可滚动主内容 ──────────────────────────────────────────
        Column(
            modifier = Modifier
                .fillMaxSize()
                .screenTopPadding
                .verticalScroll(rememberScrollState())
        ) {
            // ── 顶部标题栏（右侧有红色垃圾桶按钮） ─────────────────
            FormTopBar(
                title = "编辑档案",
                onBack = onBack,
                rightContent = {
                    Box(
                        modifier = Modifier
                            .size(40.dp)
                            .shadow(
                                elevation = 6.dp,
                                shape = CircleShape,
                                ambientColor = Color(0x388CA578),
                                spotColor = Color(0x288CA578)
                            )
                            .clip(CircleShape)
                            .background(CardBg)
                            .clickable { showArchiveSheet = true },
                        contentAlignment = Alignment.Center
                    ) {
                        Icon(
                            imageVector = Icons.Outlined.Delete,
                            contentDescription = "终结并归档",
                            tint = Color(0xFFC06050),
                            modifier = Modifier.size(18.dp)
                        )
                    }
                }
            )

            // ── 页面内容区域 ──────────────────────────────────────
            Column(
                modifier = Modifier.padding(
                    PaddingValues(start = 18.dp, end = 18.dp, bottom = 32.dp)
                )
            ) {

                // ── 图标选择卡片 ─────────────────────────────────
                FormCard {
                    FormSectionHeader(text = "档案图标")
                    IconSelector(
                        selectedIconName = vm.iconName,
                        onIconSelected = { iconName, _, _, _ -> vm.iconName = iconName }
                    )
                }

                Spacer(modifier = Modifier.height(14.dp))

                // ── 基本信息卡片（预填） ──────────────────────────
                FormCard {
                    FormSectionHeader(text = "基本信息")

                    // 植物名称
                    FormFieldGroup {
                        FormLabel(text = "植物名称", required = true)
                        FormTextField(
                            value = vm.name,
                            onValueChange = {
                                vm.name = it
                                if (it.isNotBlank()) showNameError = false
                            },
                            placeholder = "如：绿萝、发财树、吊兰…"
                        )
                        if (showNameError) {
                            Text(
                                text = "请填写植物名称",
                                fontSize = 11.sp,
                                color = Color(0xFFC06050),
                                modifier = Modifier.padding(top = 4.dp)
                            )
                        }
                    }

                    // 品种（必填）
                    FormFieldGroup {
                        FormLabel(text = "品种", required = true)
                        FormTextField(
                            value = vm.species,
                            onValueChange = {
                                vm.species = it
                                if (it.isNotBlank()) showSpeciesError = false
                            },
                            placeholder = "必填"
                        )
                        if (showSpeciesError) {
                            Text(
                                text = "请填写品种",
                                fontSize = 12.sp,
                                color = Color(0xFFC06050),
                                modifier = Modifier.padding(top = 4.dp)
                            )
                        }
                    }

                    // 入手日期
                    FormFieldGroupLast {
                        FormLabel(text = "入手日期", required = true)
                        DatePickerField(
                            timestampMs = vm.acquiredDate,
                            onDateChanged = { vm.acquiredDate = it }
                        )
                    }
                }

                Spacer(modifier = Modifier.height(14.dp))

                // ── 养护设置卡片 ──────────────────────────────────
                FormCard {
                    FormSectionHeader(text = "养护设置")

                    // 浇水间隔
                    FormFieldGroup {
                        FormLabel(text = "浇水间隔", required = true)
                        WateringIntervalPicker(
                            selectedDays = vm.wateringIntervalDays,
                            onDaysSelected = { vm.wateringIntervalDays = it }
                        )
                    }

                    // 养护备注
                    FormFieldGroupLast {
                        FormLabel(text = "养护备注")
                        FormTextArea(
                            value = vm.notes,
                            onValueChange = { vm.notes = it },
                            placeholder = "养护要点…"
                        )
                    }
                }

                Spacer(modifier = Modifier.height(14.dp))

                // ── 危险区域卡片（.danger-card） ──────────────────
                DangerCard(onArchiveClick = { showArchiveSheet = true })

                Spacer(modifier = Modifier.height(20.dp))

                // ── 操作按钮 ─────────────────────────────────────
                FormActionButtons(
                    cancelText = "取消",
                    confirmText = "保存修改",
                    onCancel = onBack,
                    onConfirm = {
                        if (vm.name.isBlank()) {
                            showNameError = true
                        } else if (vm.species.isBlank()) {
                            showSpeciesError = true
                        } else {
                            vm.updatePlant(onSuccess = onSaved)
                        }
                    }
                )
            }
        }

        // ── 终结确认底部弹窗（对应原型 .overlay + .sheet） ─────────
        if (showArchiveSheet) {
            ArchiveConfirmSheet(
                onDismiss = { showArchiveSheet = false },
                onConfirm = {
                    vm.archivePlant(onSuccess = onArchived)
                }
            )
        }
    }
}

// ─────────────────────────────────────────────────────────────────
// 私有子组件
// ─────────────────────────────────────────────────────────────────

/**
 * 植物状态胶囊选择组（对应原型 .status-group）
 * 四种状态：存活中 / 休眠中 / 病恹恹 / 已终结
 */
@Composable
private fun StatusChipGroup(
    currentStatus: String,
    onStatusSelected: (String) -> Unit
) {
    // (statusValue, displayLabel, isWarnStyle)
    val options = listOf(
        Triple("alive", "🌱 存活中", false),
        Triple("dormant", "😴 休眠中", false),
        Triple("sick", "🤒 病恹恹", true),
        Triple("archived", "🪦 已终结", true),
    )

    Row(horizontalArrangement = androidx.compose.foundation.layout.Arrangement.spacedBy(8.dp)) {
        options.forEach { (statusValue, label, isWarn) ->
            val isSelected = currentStatus == statusValue
            val selectedBg = if (isWarn) Color(0xFFFFEEEB) else GreenLightBg
            val selectedBorder = if (isWarn) Color(0xFFC06050) else GreenDark
            val selectedText = if (isWarn) Color(0xFFC06050) else GreenDark

            Box(
                modifier = Modifier
                    .border(
                        1.5.dp,
                        if (isSelected) selectedBorder else Color.Transparent,
                        RoundedCornerShape(20.dp)
                    )
                    .clip(RoundedCornerShape(20.dp))
                    .background(if (isSelected) selectedBg else BtnBg)
                    .clickable { onStatusSelected(statusValue) }
                    .padding(horizontal = 16.dp, vertical = 8.dp)
            ) {
                Text(
                    text = label,
                    fontSize = 13.sp,
                    fontWeight = FontWeight.SemiBold,
                    color = if (isSelected) selectedText else TextColor
                )
            }
        }
    }
}

/**
 * 危险区域卡片（对应原型 .danger-card）
 * border: 1.5px solid rgba(192,96,80,.18)，内有终结按钮
 */
@Composable
private fun DangerCard(onArchiveClick: () -> Unit) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .shadow(
                elevation = 8.dp,
                shape = RoundedCornerShape(24.dp),
                ambientColor = Color(0x478CA578),
                spotColor = Color(0x288CA578)
            )
            .clip(RoundedCornerShape(24.dp))
            .background(CardBg)
            .border(1.5.dp, Color(0x2EC06050), RoundedCornerShape(24.dp))
            .padding(20.dp)
    ) {
        // 节标题（红色）
        Text(
            text = "危险操作".uppercase(),
            fontSize = 11.sp,
            fontWeight = FontWeight.Bold,
            color = Color(0xFFC06050),
            letterSpacing = 0.8.sp,
            modifier = Modifier.padding(bottom = 14.dp)
        )

        // 终结按钮（.danger-btn）
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .clip(RoundedCornerShape(14.dp))
                .background(Color(0xFFFFF0EE))
                .border(1.5.dp, Color(0x4DC06050), RoundedCornerShape(14.dp))
                .clickable(onClick = onArchiveClick)
                .padding(vertical = 14.dp),
            contentAlignment = Alignment.Center
        ) {
            Text(
                text = "终结这株植物并归档",
                fontSize = 14.sp,
                fontWeight = FontWeight.SemiBold,
                color = Color(0xFFC06050)
            )
        }
    }
}

/**
 * 终结确认底部弹窗（对应原型 .overlay + .sheet）
 * 半透明黑色遮罩 + 从底部滑出的白色卡片
 */
@Composable
private fun ArchiveConfirmSheet(
    onDismiss: () -> Unit,
    onConfirm: () -> Unit
) {
    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(Color(0x66000000))
            .clickable(
                indication = null,
                interactionSource = remember { MutableInteractionSource() }
            ) { onDismiss() }
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .align(Alignment.BottomCenter)
                .clip(RoundedCornerShape(topStart = 28.dp, topEnd = 28.dp))
                .background(CardBg)
                .clickable(
                    indication = null,
                    interactionSource = remember { MutableInteractionSource() }
                ) { /* 吃掉点击事件，防止穿透到遮罩 */ }
                .padding(horizontal = 24.dp)
                .padding(top = 28.dp, bottom = 16.dp)
                .navigationBarsPadding()
        ) {
            // 标题
            Text(
                text = "终结这株植物？",
                fontSize = 18.sp,
                fontWeight = FontWeight.Bold,
                color = TextColor
            )
            Spacer(modifier = Modifier.height(8.dp))

            // 说明文字
            Text(
                text = "档案将被标记为「已终结」并移入归档，浇水提醒将停止。\n档案不会被删除，你仍可随时查阅历史记录。",
                fontSize = 14.sp,
                color = MutedColor,
                lineHeight = 22.sp
            )
            Spacer(modifier = Modifier.height(24.dp))

            // 确认终结按钮（红色）
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(14.dp))
                    .background(Color(0xFFC06050))
                    .clickable(onClick = onConfirm)
                    .padding(vertical = 15.dp),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = "确认终结并归档",
                    fontSize = 15.sp,
                    fontWeight = FontWeight.Bold,
                    color = Color.White
                )
            }

            Spacer(modifier = Modifier.height(10.dp))

            // 取消按钮
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(14.dp))
                    .background(BtnBg)
                    .clickable(onClick = onDismiss)
                    .padding(vertical = 15.dp),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = "取消",
                    fontSize = 15.sp,
                    fontWeight = FontWeight.SemiBold,
                    color = TextColor
                )
            }

            Spacer(modifier = Modifier.height(8.dp))
        }
    }
}
