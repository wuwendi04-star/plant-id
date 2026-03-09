package com.example.plant_id.ui.screens

import android.app.Application
import android.content.Intent
import android.nfc.NfcAdapter
import android.provider.Settings
import androidx.compose.animation.core.FastOutSlowInEasing
import androidx.compose.animation.core.LinearEasing
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Close
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.rotate
import androidx.compose.ui.draw.scale
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.viewmodel.compose.viewModel
import com.example.plant_id.ui.navigation.screenTopPadding
import com.example.plant_id.ui.theme.BtnBg
import com.example.plant_id.ui.theme.CardBg
import com.example.plant_id.ui.theme.GreenDark
import com.example.plant_id.ui.theme.MutedColor
import com.example.plant_id.ui.theme.TextColor
import com.example.plant_id.ui.viewmodel.NfcViewModel

/**
 * NFC 状态枚举
 */
enum class NfcStatus {
    NOT_SUPPORTED,  // 设备不支持 NFC
    DISABLED,       // NFC 已关闭
    READY           // NFC 就绪，可扫描
}

/**
 * 阶段十一：NFC 扫描引导页
 * - 三层脉冲环 + 旋转弧动画（参考原型 nfc-scan.html）
 * - 中心 NFC 十字准星图标
 * - 底部「无 NFC 标签，直接创建」按钮
 * - 系统检测到 NFC 标签后，Navigation.kt 自动处理路由跳转
 */
@Composable
fun NfcScanScreen(
    onBack: () -> Unit,
    onSkipNfc: () -> Unit,
    nfcVm: NfcViewModel = viewModel()
) {
    val context = LocalContext.current

    // 检测设备 NFC 能力（同步操作）
    val nfcStatus = remember {
        val adapter = NfcAdapter.getDefaultAdapter(context)
        when {
            adapter == null -> NfcStatus.NOT_SUPPORTED
            !adapter.isEnabled -> NfcStatus.DISABLED
            else -> NfcStatus.READY
        }
    }

    // 进入页面时开启「创建模式」，离开时自动关闭
    // 确保只有在此扫描页才会把未绑定标签导向创建页
    DisposableEffect(Unit) {
        nfcVm.setCreateMode(true)
        onDispose { nfcVm.setCreateMode(false) }
    }

    val infiniteTransition = rememberInfiniteTransition(label = "nfc-scan")

    // Ring 1：从暗→亮脉冲（1800ms）
    val r1Anim by infiniteTransition.animateFloat(
        initialValue = 0f,
        targetValue = 1f,
        animationSpec = infiniteRepeatable(
            animation = tween(1800, easing = FastOutSlowInEasing),
            repeatMode = RepeatMode.Reverse
        ),
        label = "r1"
    )

    // Ring 2：从亮→暗脉冲（2200ms），与 Ring1 反相形成自然交错
    val r2Anim by infiniteTransition.animateFloat(
        initialValue = 1f,
        targetValue = 0f,
        animationSpec = infiniteRepeatable(
            animation = tween(2200, easing = FastOutSlowInEasing),
            repeatMode = RepeatMode.Reverse
        ),
        label = "r2"
    )

    // 旋转弧（线性匀速，2500ms/圈）
    val spinDeg by infiniteTransition.animateFloat(
        initialValue = 0f,
        targetValue = 360f,
        animationSpec = infiniteRepeatable(
            animation = tween(2500, easing = LinearEasing),
            repeatMode = RepeatMode.Restart
        ),
        label = "spin"
    )

    // 推导各环动画参数
    val r1Alpha = 0.22f + r1Anim * 0.78f
    val r1Scale = 0.93f + r1Anim * 0.08f
    val r2Alpha = 0.22f + r2Anim * 0.78f
    val r2Scale = 0.93f + r2Anim * 0.08f

    Box(
        modifier = Modifier
            .fillMaxSize()
            .screenTopPadding
    ) {

        // ── 关闭按钮（左上角，浮雕圆形卡片）─────────────────────────
        Box(
            modifier = Modifier
                .padding(start = 18.dp, top = 14.dp)
                .size(42.dp)
                .shadow(
                    elevation = 6.dp,
                    shape = CircleShape,
                    ambientColor = Color(0x288CA578),
                    spotColor = Color(0x288CA578)
                )
                .background(CardBg, CircleShape)
                .clickable(
                    indication = null,
                    interactionSource = remember { MutableInteractionSource() },
                    onClick = onBack
                ),
            contentAlignment = Alignment.Center
        ) {
            Icon(
                imageVector = Icons.Outlined.Close,
                contentDescription = "返回",
                tint = TextColor,
                modifier = Modifier.size(18.dp)
            )
        }

        // ── 主内容区（垂直居中，底部留出按钮空间）──────────────────
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(horizontal = 36.dp)
                .padding(bottom = 140.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center
        ) {

            when (nfcStatus) {
                NfcStatus.NOT_SUPPORTED -> {
                    // 设备不支持 NFC
                    Text(
                        text = "📵",
                        fontSize = 56.sp
                    )

                    Spacer(Modifier.height(20.dp))

                    Text(
                        text = "设备不支持 NFC",
                        fontFamily = FontFamily.Serif,
                        fontSize = 26.sp,
                        fontWeight = FontWeight.Normal,
                        color = TextColor,
                        textAlign = TextAlign.Center
                    )

                    Spacer(Modifier.height(10.dp))

                    Text(
                        text = "当前设备没有 NFC 硬件，请直接创建档案",
                        fontSize = 14.sp,
                        color = MutedColor,
                        textAlign = TextAlign.Center,
                        lineHeight = 22.sp
                    )
                }

                NfcStatus.DISABLED -> {
                    // NFC 已关闭
                    Text(
                        text = "📴",
                        fontSize = 56.sp
                    )

                    Spacer(Modifier.height(20.dp))

                    Text(
                        text = "NFC 未开启",
                        fontFamily = FontFamily.Serif,
                        fontSize = 26.sp,
                        fontWeight = FontWeight.Normal,
                        color = TextColor,
                        textAlign = TextAlign.Center
                    )

                    Spacer(Modifier.height(10.dp))

                    Text(
                        text = "请前往系统设置开启 NFC 后再试",
                        fontSize = 14.sp,
                        color = MutedColor,
                        textAlign = TextAlign.Center,
                        lineHeight = 22.sp
                    )
                }

                NfcStatus.READY -> {
                    // NFC 就绪，显示原有的扫描动画
                    // ── NFC 动画区域 (200dp 容器)────────────────────────────
                    Box(
                        modifier = Modifier.size(200.dp),
                        contentAlignment = Alignment.Center
                    ) {

                        // Ring 1 —— 最外层脉冲环（180dp）
                        Box(
                            modifier = Modifier
                                .size(180.dp)
                                .scale(r1Scale)
                                .border(
                                    width = 2.dp,
                                    color = GreenDark.copy(alpha = r1Alpha * 0.30f),
                                    shape = CircleShape
                                )
                        )

                        // Ring 2 —— 中层脉冲环（130dp），与 Ring1 交错
                        Box(
                            modifier = Modifier
                                .size(130.dp)
                                .scale(r2Scale)
                                .border(
                                    width = 2.dp,
                                    color = GreenDark.copy(alpha = r2Alpha * 0.30f),
                                    shape = CircleShape
                                )
                        )

                        // Ring 3 —— 内层静态实底环（84dp）
                        Box(
                            modifier = Modifier
                                .size(84.dp)
                                .background(GreenDark.copy(alpha = 0.08f), CircleShape)
                                .border(2.dp, GreenDark.copy(alpha = 0.40f), CircleShape)
                        )

                        // 旋转弧（Canvas 绘制，仅头部 80° 可见弧段）
                        Canvas(
                            modifier = Modifier
                                .size(160.dp)
                                .rotate(spinDeg)
                        ) {
                            val sw = 2.5.dp.toPx()
                            val inset = sw / 2f
                            drawArc(
                                color = GreenDark,
                                startAngle = -90f,
                                sweepAngle = 80f,
                                useCenter = false,
                                topLeft = Offset(inset, inset),
                                size = Size(size.width - sw, size.height - sw),
                                style = Stroke(width = sw, cap = StrokeCap.Round)
                            )
                        }

                        // 核心圆（54dp，暖米色卡片质感 + NFC 准星图标）
                        Box(
                            modifier = Modifier
                                .size(54.dp)
                                .shadow(
                                    elevation = 10.dp,
                                    shape = CircleShape,
                                    ambientColor = Color(0x308CA578),
                                    spotColor = Color(0x50FFFFFF)
                                )
                                .background(CardBg, CircleShape),
                            contentAlignment = Alignment.Center
                        ) {
                            Canvas(modifier = Modifier.size(28.dp)) {
                                val cx = size.width / 2f
                                val cy = size.height / 2f
                                val sw = 2.dp.toPx()
                                val r = size.width * 0.32f          // 外圆半径
                                val lineGap = r + 1.8.dp.toPx()            // 短线起始距离
                                val lineLen = size.width * 0.15f          // 短线长度

                                // 外圆
                                drawCircle(
                                    color = GreenDark,
                                    radius = r,
                                    center = Offset(cx, cy),
                                    style = Stroke(sw)
                                )

                                // 四向辐射短线（十字准星）
                                drawLine(
                                    GreenDark,
                                    Offset(cx - lineGap - lineLen, cy),
                                    Offset(cx - lineGap, cy),
                                    sw
                                )
                                drawLine(
                                    GreenDark,
                                    Offset(cx + lineGap, cy),
                                    Offset(cx + lineGap + lineLen, cy),
                                    sw
                                )
                                drawLine(
                                    GreenDark,
                                    Offset(cx, cy - lineGap - lineLen),
                                    Offset(cx, cy - lineGap),
                                    sw
                                )
                                drawLine(
                                    GreenDark,
                                    Offset(cx, cy + lineGap),
                                    Offset(cx, cy + lineGap + lineLen),
                                    sw
                                )

                                // 中心实心圆点
                                drawCircle(GreenDark, 2.5.dp.toPx(), Offset(cx, cy))
                            }
                        }
                    } // end Box animation

                    Spacer(Modifier.height(36.dp))

                    // ── 标题（Georgia 衬线体）───────────────────────────────
                    Text(
                        text = "准备扫描",
                        fontFamily = FontFamily.Serif,
                        fontSize = 26.sp,
                        fontWeight = FontWeight.Normal,
                        color = TextColor,
                        textAlign = TextAlign.Center
                    )

                    Spacer(Modifier.height(10.dp))

                    // ── 说明文字 ────────────────────────────────────────────
                    Text(
                        text = "将手机背面靠近 NFC 标签\n保持稳定，自动识别处理",
                        fontSize = 14.sp,
                        color = MutedColor,
                        textAlign = TextAlign.Center,
                        lineHeight = 22.sp
                    )

                    Spacer(Modifier.height(28.dp))

                    // ── 提示框 ──────────────────────────────────────────────
                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .background(GreenDark.copy(alpha = 0.10f), RoundedCornerShape(14.dp))
                            .padding(horizontal = 16.dp, vertical = 12.dp)
                    ) {
                        Text(
                            text = "💡  标签通常贴在花盆底部或侧面，防水款最佳",
                            fontSize = 12.sp,
                            color = GreenDark,
                            lineHeight = 18.sp
                        )
                    }
                }
            }
        }

        // ── 底部「无 NFC 标签」按钮 或 「前往设置」按钮 ───────────────────────────────
        Column(
            modifier = Modifier
                .align(Alignment.BottomCenter)
                .navigationBarsPadding()
                .padding(bottom = 36.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            when (nfcStatus) {
                NfcStatus.DISABLED -> {
                    // NFC 已关闭：显示"前往设置"按钮
                    Text(
                        text = "开启 NFC？",
                        fontSize = 12.sp,
                        color = MutedColor.copy(alpha = 0.7f)
                    )

                    Box(
                        modifier = Modifier
                            .shadow(
                                elevation = 4.dp,
                                shape = RoundedCornerShape(50.dp),
                                ambientColor = Color(0x208CA578),
                                spotColor = Color(0x208CA578)
                            )
                            .background(BtnBg, RoundedCornerShape(50.dp))
                            .clickable(
                                indication = null,
                                interactionSource = remember { MutableInteractionSource() },
                                onClick = {
                                    val intent = Intent(Settings.ACTION_NFC_SETTINGS)
                                    context.startActivity(intent)
                                }
                            )
                            .padding(horizontal = 28.dp, vertical = 13.dp),
                        contentAlignment = Alignment.Center
                    ) {
                        Text(
                            text = "前往系统设置",
                            fontSize = 14.sp,
                            color = MutedColor,
                            fontWeight = FontWeight.Medium
                        )
                    }
                }

                NfcStatus.NOT_SUPPORTED,
                NfcStatus.READY -> {
                    // 不支持 NFC 或 NFC 就绪：显示"无 NFC 标签"按钮
                    Text(
                        text = "没有标签？",
                        fontSize = 12.sp,
                        color = MutedColor.copy(alpha = 0.7f)
                    )

                    Box(
                        modifier = Modifier
                            .shadow(
                                elevation = 4.dp,
                                shape = RoundedCornerShape(50.dp),
                                ambientColor = Color(0x208CA578),
                                spotColor = Color(0x208CA578)
                            )
                            .background(BtnBg, RoundedCornerShape(50.dp))
                            .clickable(
                                indication = null,
                                interactionSource = remember { MutableInteractionSource() },
                                onClick = onSkipNfc
                            )
                            .padding(horizontal = 28.dp, vertical = 13.dp),
                        contentAlignment = Alignment.Center
                    ) {
                        Text(
                            text = "无 NFC 标签，直接创建",
                            fontSize = 14.sp,
                            color = MutedColor,
                            fontWeight = FontWeight.Medium
                        )
                    }
                }
            }
        }
    }
}
