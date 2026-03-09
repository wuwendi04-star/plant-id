package com.example.plant_id.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import android.app.Application
import androidx.compose.ui.platform.LocalContext
import androidx.lifecycle.viewmodel.compose.viewModel
import com.example.plant_id.ui.components.PlantIllustration
import com.example.plant_id.ui.navigation.FLOATING_NAV_BOTTOM_PADDING
import com.example.plant_id.ui.navigation.screenTopPadding
import com.example.plant_id.ui.theme.BtnBg
import com.example.plant_id.ui.theme.CardBg
import com.example.plant_id.ui.theme.CardDivider
import com.example.plant_id.ui.theme.GreenDark
import com.example.plant_id.ui.theme.MutedColor
import com.example.plant_id.ui.theme.TextColor
import com.example.plant_id.ui.theme.UrgentColor
import com.example.plant_id.ui.viewmodel.CareViewModel
import com.example.plant_id.ui.viewmodel.PlantCareItem

// 养护提醒页，完整对应原型 notifications.html
// 展示超期/今日到期/即将到期植物，支持直接浇水和跳转档案
@Composable
fun CareScreen(
    onNavigateToPlantDetail: (Long) -> Unit = {}
) {
    val vm: CareViewModel = viewModel(
        factory = CareViewModel.factory(LocalContext.current.applicationContext as Application)
    )

    val overdueItems = vm.careItems.filter { it.isOverdue }
    val todayItems = vm.careItems.filter { it.isDueToday }
    val upcomingItems = vm.careItems.filter { it.isUpcoming }
    val todayAndUpcoming = todayItems + upcomingItems
    val attentionCount = overdueItems.size + todayItems.size

    Column(
        modifier = Modifier
            .fillMaxSize()
            .screenTopPadding
    ) {
        Spacer(modifier = Modifier.height(14.dp))

        // ── 标题 ──────────────────────────────────────────────────
        Text(
            text = "养护提醒",
            fontFamily = FontFamily.Serif,
            fontSize = 28.sp,
            fontWeight = FontWeight.Normal,
            color = TextColor,
            modifier = Modifier.padding(horizontal = 18.dp)
        )
        Spacer(modifier = Modifier.height(4.dp))

        // 副标题：根据状态显示不同文案
        val subtitle = when {
            vm.isLoading -> "加载中..."
            attentionCount > 0 -> "今日需要处理 $attentionCount 株植物"
            upcomingItems.isNotEmpty() -> "${upcomingItems.size} 株植物即将到期"
            else -> "所有植物状态良好"
        }
        Text(
            text = subtitle,
            fontSize = 13.sp,
            color = MutedColor,
            modifier = Modifier.padding(horizontal = 18.dp)
        )
        Spacer(modifier = Modifier.height(24.dp))

        // ── 列表区域 ──────────────────────────────────────────────
        LazyColumn(
            modifier = Modifier.fillMaxSize(),
            contentPadding = PaddingValues(
                start = 18.dp,
                end = 18.dp,
                bottom = FLOATING_NAV_BOTTOM_PADDING.dp
            )
        ) {
            // 无任何需要关注的植物 → 全部正常空状态
            if (!vm.isLoading && overdueItems.isEmpty() && todayAndUpcoming.isEmpty()) {
                item {
                    AllGoodCard()
                }
                return@LazyColumn
            }

            // ── 🔴 立即处理（超期） ──────────────────────────────
            if (overdueItems.isNotEmpty()) {
                item(key = "label_urgent") {
                    CareGroupLabel(emoji = "🔴", label = "立即处理")
                    Spacer(modifier = Modifier.height(10.dp))
                }
                items(overdueItems, key = { it.plant.id }) { careItem ->
                    CareItemCard(
                        item = careItem,
                        onViewDetail = { onNavigateToPlantDetail(careItem.plant.id) }
                    )
                    Spacer(modifier = Modifier.height(10.dp))
                }
                item(key = "spacer_urgent") {
                    Spacer(modifier = Modifier.height(12.dp))
                }
            }

            // ── 📅 今日提醒（今日到期 + 2天内即将到期） ─────────
            if (todayAndUpcoming.isNotEmpty()) {
                item(key = "label_today") {
                    CareGroupLabel(emoji = "📅", label = "今日提醒")
                    Spacer(modifier = Modifier.height(10.dp))
                }
                items(todayAndUpcoming, key = { it.plant.id }) { careItem ->
                    CareItemCard(
                        item = careItem,
                        onViewDetail = { onNavigateToPlantDetail(careItem.plant.id) }
                    )
                    Spacer(modifier = Modifier.height(10.dp))
                }
            }
        }
    }
}

// ── 私有组件 ──────────────────────────────────────────────────────

// 分组标题（.group-label 样式）
@Composable
private fun CareGroupLabel(emoji: String, label: String) {
    Row(
        verticalAlignment = Alignment.CenterVertically,
        modifier = Modifier.fillMaxWidth()
    ) {
        Text(
            text = "$emoji  $label",
            fontSize = 11.sp,
            fontWeight = FontWeight.Bold,
            color = MutedColor,
            letterSpacing = 0.8.sp
        )
        Spacer(modifier = Modifier.width(8.dp))
        Box(
            modifier = Modifier
                .weight(1f)
                .height(1.dp)
                .background(CardDivider)
        )
    }
}

// 养护提醒卡片（.notice-card 样式）
// 包含：左侧彩色边框、植物插图、标题/描述、行动按钮
@Composable
private fun CareItemCard(
    item: PlantCareItem,
    onViewDetail: () -> Unit
) {
    // 左侧边框颜色
    val borderColor: Color = when {
        item.isOverdue -> UrgentColor                    // 超期：红色
        item.isDueToday -> GreenDark                    // 今日：绿色
        else -> Color.Transparent                        // 即将：无边框
    }
    // 图标背景色
    val iconBg: Color = when {
        item.isOverdue -> Color(0x1FD46A50)             // rgba(212,106,80,.12)
        item.isDueToday -> Color(0x1A3D5C33)            // rgba(61,92,51,.1)
        else -> Color(0x0D000000)                        // rgba(0,0,0,.05)
    }
    // 标题文案
    val titleText = when {
        item.daysSinceWatering < 0 -> "${item.plant.name} · 从未浇水"
        item.isOverdue -> "${item.plant.name} · 超期未浇水"
        item.isDueToday -> "${item.plant.name} · 该浇水了"
        item.daysUntilDue == 1 -> "${item.plant.name} · 明天需浇水"
        else -> "${item.plant.name} · ${item.daysUntilDue} 天后需浇水"
    }
    // 描述文案
    val descText = when {
        item.daysSinceWatering < 0 ->
            "从未记录浇水，请查看档案并补充"

        item.isOverdue ->
            "距上次浇水已 ${item.daysSinceWatering} 天，超过设定的 ${item.plant.wateringIntervalDays} 天间隔。"

        item.isDueToday ->
            "距上次浇水 ${item.daysSinceWatering} 天，已达到设定的浇水间隔。"

        else ->
            "已浇水 ${item.daysSinceWatering} 天，${item.daysUntilDue} 天后需要浇水。"
    }

    val hasBorder = borderColor != Color.Transparent
    val borderWidthPx = if (hasBorder) 4.dp else 0.dp

    Row(
        modifier = Modifier
            .fillMaxWidth()
            .shadow(
                elevation = 6.dp,
                shape = RoundedCornerShape(20.dp),
                ambientColor = Color(0x388CA578),
                spotColor = Color(0x288CA578)
            )
            .clip(RoundedCornerShape(20.dp))
            .background(CardBg)
            .drawBehind {
                if (hasBorder) {
                    drawRoundRect(
                        color = borderColor,
                        topLeft = Offset(0f, 0f),
                        size = Size(4.dp.toPx(), size.height),
                        cornerRadius = CornerRadius(0f)
                    )
                }
            }
            .clickable(onClick = onViewDetail)
            .padding(
                start = if (hasBorder) 16.dp else 16.dp,
                end = 16.dp,
                top = 16.dp,
                bottom = 16.dp
            ),
        verticalAlignment = Alignment.Top
    ) {
        // 植物插图（52×52 圆角方块）
        Box(
            modifier = Modifier
                .size(52.dp)
                .clip(RoundedCornerShape(14.dp))
                .background(iconBg),
            contentAlignment = Alignment.Center
        ) {
            PlantIllustration(
                iconName = item.plant.iconName,
                modifier = Modifier.size(width = 36.dp, height = 42.dp)
            )
        }

        Spacer(modifier = Modifier.width(14.dp))

        // 文字内容区
        Column(modifier = Modifier.weight(1f)) {
            // 标题行（含未读小圆点）
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.Top
            ) {
                Text(
                    text = titleText,
                    fontSize = 14.sp,
                    fontWeight = FontWeight.Bold,
                    color = TextColor,
                    lineHeight = 20.sp,
                    modifier = Modifier.weight(1f)
                )
                // 超期/今日显示绿色未读圆点
                if (item.needsAttention) {
                    Box(
                        modifier = Modifier
                            .padding(top = 4.dp, start = 6.dp)
                            .size(8.dp)
                            .background(GreenDark, CircleShape)
                    )
                }
            }

            Spacer(modifier = Modifier.height(4.dp))
            Text(
                text = descText,
                fontSize = 12.sp,
                color = MutedColor,
                lineHeight = 18.sp
            )

            // 操作按钮行
            Spacer(modifier = Modifier.height(8.dp))
            Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                // 按钮：查看档案
                CareActionButton(
                    text = "查看档案",
                    isPrimary = true,
                    onClick = onViewDetail
                )
            }
        }
    }
}

// 行动按钮（.nca 样式，胶囊形）
@Composable
private fun CareActionButton(
    text: String,
    isPrimary: Boolean,
    onClick: () -> Unit
) {
    Box(
        modifier = Modifier
            .clip(RoundedCornerShape(50.dp))
            .background(if (isPrimary) GreenDark else BtnBg)
            .clickable(onClick = onClick)
            .padding(horizontal = 12.dp, vertical = 6.dp)
    ) {
        Text(
            text = text,
            fontSize = 11.sp,
            fontWeight = FontWeight.Bold,
            color = if (isPrimary) Color.White else MutedColor
        )
    }
}

// 全部正常时的空状态卡片
@Composable
private fun AllGoodCard() {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .shadow(
                elevation = 6.dp,
                shape = RoundedCornerShape(20.dp),
                ambientColor = Color(0x388CA578),
                spotColor = Color(0x288CA578)
            )
            .clip(RoundedCornerShape(20.dp))
            .background(CardBg)
            .padding(16.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Box(
            modifier = Modifier
                .size(52.dp)
                .clip(RoundedCornerShape(14.dp))
                .background(Color(0x0D000000)),
            contentAlignment = Alignment.Center
        ) {
            Text(text = "✅", fontSize = 24.sp)
        }
        Spacer(modifier = Modifier.width(14.dp))
        Column {
            Text(
                text = "全部植物状态良好",
                fontSize = 14.sp,
                fontWeight = FontWeight.Bold,
                color = TextColor
            )
            Spacer(modifier = Modifier.height(4.dp))
            Text(
                text = "没有需要立即处理的养护任务，继续保持！",
                fontSize = 12.sp,
                color = MutedColor,
                lineHeight = 18.sp
            )
        }
    }
}
