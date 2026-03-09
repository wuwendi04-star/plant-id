package com.example.plant_id.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
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
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontFamily
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
import com.example.plant_id.ui.components.FormHint
import com.example.plant_id.ui.components.FormLabel
import com.example.plant_id.ui.components.FormSectionHeader
import com.example.plant_id.ui.components.FormTextArea
import com.example.plant_id.ui.components.FormTextField
import com.example.plant_id.ui.components.FormTopBar
import com.example.plant_id.ui.components.IconSelector
import com.example.plant_id.ui.components.WateringIntervalPicker
import com.example.plant_id.ui.navigation.screenTopPadding
import com.example.plant_id.ui.theme.GreenDark
import com.example.plant_id.ui.theme.MutedColor
import com.example.plant_id.ui.viewmodel.CreatePlantViewModel

/**
 * 创建新档案页面（对应原型 create-plant.html）
 *
 * @param onBack          点击返回 / 取消回调
 * @param onPlantCreated  成功创建后回调（默认与 onBack 相同，返回上一页）
 * @param nfcTagId        NFC 扫描触发创建时传入的标签 ID，为 null 表示普通创建
 */
@Composable
fun CreatePlantScreen(
    onBack: () -> Unit,
    onPlantCreated: () -> Unit = onBack,
    nfcTagId: String? = null
) {
    val vm: CreatePlantViewModel = viewModel(
        factory = CreatePlantViewModel.factory(LocalContext.current.applicationContext as Application)
    )

    // NFC 标签 ID 预填（仅在首次进入时执行一次）
    LaunchedEffect(nfcTagId) {
        nfcTagId?.let { vm.prefillNfcTag(it) }
    }

    // 名称校验错误状态
    var showNameError by remember { mutableStateOf(false) }
    var showSpeciesError by remember { mutableStateOf(false) }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .screenTopPadding
            .verticalScroll(rememberScrollState())
    ) {
        // ── 顶部标题栏 ────────────────────────────────────────────
        FormTopBar(
            title = "创建新档案",
            onBack = onBack
        )

        // ── 页面内容区域（左右 18dp 边距，对应原型 .page） ─────────
        Column(
            modifier = Modifier.padding(
                PaddingValues(start = 18.dp, end = 18.dp, bottom = 32.dp)
            )
        ) {

            // ── 图标选择卡片 ─────────────────────────────────────
            FormCard {
                FormSectionHeader(text = "选择档案图标")
                IconSelector(
                    selectedIconName = vm.iconName,
                    onIconSelected = { iconName, _, speciesDefault, notesDefault ->
                        vm.iconName = iconName
                        // 直接赋值默认值：有内容则填入，空字符串（"其他"）则清空让用户自填
                        vm.species = speciesDefault
                        vm.notes = notesDefault
                        showSpeciesError = false
                    }
                )
            }

            // ── NFC 标签信息提示（仅 NFC 触发创建时显示）────────────
            if (vm.nfcTagId.isNotBlank()) {
                Spacer(modifier = Modifier.height(14.dp))
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clip(RoundedCornerShape(12.dp))
                        .background(Color(0x1A3D5C33))
                        .padding(horizontal = 14.dp, vertical = 10.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = "📡",
                        fontSize = 16.sp
                    )
                    Column(modifier = Modifier.padding(start = 8.dp)) {
                        Text(
                            text = "NFC 标签已识别",
                            fontSize = 12.sp,
                            fontWeight = FontWeight.Bold,
                            color = GreenDark
                        )
                        Text(
                            text = "ID: ${vm.nfcTagId}",
                            fontSize = 11.sp,
                            fontFamily = FontFamily.Monospace,
                            color = MutedColor
                        )
                    }
                }
            }

            Spacer(modifier = Modifier.height(14.dp))

            // ── 基本信息卡片 ─────────────────────────────────────
            FormCard {
                FormSectionHeader(text = "基本信息")

                // 植物名称（必填）
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
                        placeholder = "如：心叶绿萝、金钱树…"
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

                // 入手日期（必填）
                FormFieldGroupLast {
                    FormLabel(text = "入手日期", required = true)
                    DatePickerField(
                        timestampMs = vm.acquiredDate,
                        onDateChanged = { vm.acquiredDate = it }
                    )
                }
            }

            Spacer(modifier = Modifier.height(14.dp))

            // ── 养护设置卡片 ─────────────────────────────────────
            FormCard {
                FormSectionHeader(text = "养护设置")

                // 浇水间隔（必填）
                FormFieldGroup {
                    FormLabel(text = "浇水间隔", required = true)
                    WateringIntervalPicker(
                        selectedDays = vm.wateringIntervalDays,
                        onDaysSelected = { vm.wateringIntervalDays = it }
                    )
                    FormHint(text = "系统将根据此频率在到期时发出提醒")
                }

                // 养护备注（可选）
                FormFieldGroupLast {
                    FormLabel(text = "养护备注")
                    FormTextArea(
                        value = vm.notes,
                        onValueChange = { vm.notes = it },
                        placeholder = "记录浇水要点、喜光/耐阴偏好等…（可选）"
                    )
                }
            }

            Spacer(modifier = Modifier.height(20.dp))

            // ── 操作按钮 ─────────────────────────────────────────
            FormActionButtons(
                cancelText = "取消",
                confirmText = "确认创建",
                onCancel = onBack,
                onConfirm = {
                    if (vm.name.isBlank()) {
                        showNameError = true
                    } else if (vm.species.isBlank()) {
                        showSpeciesError = true
                    } else {
                        vm.createPlant(onSuccess = onPlantCreated)
                    }
                }
            )
        }
    }
}
