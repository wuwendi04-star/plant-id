package com.example.plant_id.ui.navigation

import android.widget.Toast
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Home
import androidx.compose.material.icons.outlined.Notifications
import androidx.compose.material.icons.outlined.Person
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.snapshotFlow
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.navigation.NavDestination.Companion.hierarchy
import androidx.navigation.NavGraph.Companion.findStartDestination
import androidx.navigation.NavType
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import androidx.navigation.navArgument
import com.example.plant_id.ui.screens.CareScreen
import com.example.plant_id.ui.screens.CreatePlantScreen
import com.example.plant_id.ui.screens.EditPlantScreen
import com.example.plant_id.ui.screens.HomeScreen
import com.example.plant_id.ui.screens.NfcScanScreen
import com.example.plant_id.ui.screens.PhotoTimelineScreen
import com.example.plant_id.ui.screens.PlantDetailScreen
import com.example.plant_id.ui.screens.ProfileScreen
import com.example.plant_id.ui.theme.AppBackgroundBrush
import com.example.plant_id.ui.theme.GreenDark
import com.example.plant_id.ui.theme.MutedColor
import com.example.plant_id.ui.theme.NavBg
import com.example.plant_id.ui.viewmodel.HomeViewModel
import com.example.plant_id.ui.viewmodel.NfcNavEvent
import com.example.plant_id.ui.viewmodel.NfcViewModel
import android.app.Application
import kotlinx.coroutines.flow.first

/** 底部导航三个 Tab 的路由定义 */
sealed class Screen(
    val route: String,
    val label: String,
    val icon: ImageVector
) {
    object Home : Screen("home", "首页", Icons.Outlined.Home)
    object Care : Screen("care", "养护", Icons.Outlined.Notifications)
    object Profile : Screen("profile", "我的", Icons.Outlined.Person)
}

private val bottomNavItems = listOf(Screen.Home, Screen.Care, Screen.Profile)

/**
 * 主导航框架
 * - 全屏渐变背景（#C3D0AB → #D4E0BB → #E6EFCE）
 * - 底部浮动胶囊导航栏（原型风格）
 * - 植物详情页隐藏底部导航
 */
@Composable
fun MainNavigation() {
    val navController = rememberNavController()
    val navBackStackEntry by navController.currentBackStackEntryAsState()
    val currentDestination = navBackStackEntry?.destination

    // 监听 NFC / 通知深链接导航事件
    // LaunchedEffect(Unit) 只随首次 Compose 启动一次，用 snapshotFlow 持续收集 navEvent
    // 关键优势：snapshotFlow 始终先发射当前值，即使事件在 LaunchedEffect 启动前已设置也不会遗漏
    val application = LocalContext.current.applicationContext as Application
    val nfcVm: NfcViewModel = viewModel(factory = NfcViewModel.factory(application))
    val homeVm: HomeViewModel = viewModel(factory = HomeViewModel.factory(application))
    val context = LocalContext.current
    LaunchedEffect(Unit) {
        // Step 1：等待 NavController 的首个 back stack entry 出现（首页渲染完毕）
        // navBackStackEntry 是 Compose State，snapshotFlow 能正确追踪其变化
        snapshotFlow { navBackStackEntry }
            .first { it != null }

        // Step 2：NavController 就绪后持续收集 navEvent，任何时刻设置都不会错过
        snapshotFlow { nfcVm.navEvent }
            .collect { event ->
                when (event) {
                    is NfcNavEvent.GoToDetail -> {
                        navController.navigate("plant_detail/${event.plantId}")
                        nfcVm.showSuccessDialog()  // 显示成功弹窗
                        nfcVm.consumeNavEvent()
                    }

                    is NfcNavEvent.GoToCreate -> {
                        navController.navigate("create_plant?nfcTagId=${event.nfcTagId}")
                        nfcVm.consumeNavEvent()
                    }

                    is NfcNavEvent.TagOrphaned -> {
                        // 标签对应的植物档案已删除，提示用户而非静默打开首页
                        Toast.makeText(
                            context,
                            "该 NFC 标签绑定的植物档案已删除",
                            Toast.LENGTH_SHORT
                        ).show()
                        nfcVm.consumeNavEvent()
                    }

                    NfcNavEvent.None -> Unit
                }
            }
    }

    // 只在三个主 Tab 显示底部导航
    val showBottomNav = bottomNavItems.any { it.route == currentDestination?.route }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(AppBackgroundBrush)
    ) {
        // ── NavHost（全屏，各页面自行处理顶部状态栏 padding） ──────
        NavHost(
            navController = navController,
            startDestination = Screen.Home.route,
            modifier = Modifier.fillMaxSize()
        ) {
            composable(Screen.Home.route) {
                HomeScreen(
                    viewModel = homeVm,
                    onNavigateToPlantDetail = { plantId ->
                        navController.navigate("plant_detail/$plantId")
                    },
                    onNavigateToCreatePlant = {
                        navController.navigate("nfc_scan")
                    }
                )
            }

            // NFC 扫描引导页（阶段十一：点击"添加"后进入此页）
            composable("nfc_scan") {
                NfcScanScreen(
                    onBack = { navController.popBackStack() },
                    onSkipNfc = {
                        // 无 NFC 标签：弹出扫描页，直接进创建页（无 tagId）
                        navController.navigate("create_plant") {
                            popUpTo("nfc_scan") { inclusive = true }
                        }
                    },
                    // 必须显式传入 Activity 级 nfcVm，避免 NavHost 内 viewModel() 返回
                    // NavBackStackEntry 级别的独立实例（与 MainActivity/Navigation 实例不同），
                    // 导致 setCreateMode(true) 和 processTag 操作不同对象而失效
                    nfcVm = nfcVm
                )
            }
            composable(Screen.Care.route) {
                CareScreen(
                    onNavigateToPlantDetail = { plantId ->
                        navController.navigate("plant_detail/$plantId")
                    }
                )
            }
            composable(Screen.Profile.route) { ProfileScreen() }

            // 创建档案页（无底部导航）支持可选 NFC 标签 ID 参数
            composable(
                route = "create_plant?nfcTagId={nfcTagId}",
                arguments = listOf(navArgument("nfcTagId") {
                    type = NavType.StringType
                    nullable = true
                    defaultValue = null
                })
            ) { backStackEntry ->
                val passedNfcTagId = backStackEntry.arguments?.getString("nfcTagId")
                CreatePlantScreen(
                    nfcTagId = passedNfcTagId,
                    onBack = { navController.popBackStack() },
                    onPlantCreated = {
                        // 创建成功后直接回到首页（清除 nfc_scan、create_plant 的回退栈）
                        navController.popBackStack(Screen.Home.route, inclusive = false)
                    }
                )
            }

            // 编辑档案页（无底部导航）
            composable(
                route = "edit_plant/{plantId}",
                arguments = listOf(navArgument("plantId") { type = NavType.LongType })
            ) { backStackEntry ->
                val plantId = backStackEntry.arguments?.getLong("plantId") ?: 0L
                EditPlantScreen(
                    plantId = plantId,
                    onBack = { navController.popBackStack() },
                    onSaved = { navController.popBackStack() },
                    onArchived = {
                        // 归档后弹出到首页（清除详情和编辑页的回退栈）
                        navController.popBackStack(Screen.Home.route, inclusive = false)
                    }
                )
            }

            // 植物详情页（无底部导航）
            composable(
                route = "plant_detail/{plantId}",
                arguments = listOf(navArgument("plantId") { type = NavType.LongType })
            ) { backStackEntry ->
                val plantId = backStackEntry.arguments?.getLong("plantId") ?: 0L
                PlantDetailScreen(
                    plantId = plantId,
                    onBack = { navController.popBackStack() },
                    onNavigateToEdit = { pid ->
                        navController.navigate("edit_plant/$pid")
                    },
                    onNavigateToPhotoTimeline = { pid ->
                        navController.navigate("photo_timeline/$pid")
                    },
                    onArchived = {
                        // 归档后弹出到首页（清除详情页回退栈）
                        navController.popBackStack(Screen.Home.route, inclusive = false)
                    },
                    onDeleted = {
                        // 删除后返回首页并定位到「已归档」Tab
                        homeVm.selectedTab = 1
                        navController.popBackStack(Screen.Home.route, inclusive = false)
                    },
                    nfcVm = nfcVm  // 传入 Activity 作用域的同一实例
                )
            }

            // 照片时间线页（无底部导航）
            composable(
                route = "photo_timeline/{plantId}",
                arguments = listOf(navArgument("plantId") { type = NavType.LongType })
            ) { backStackEntry ->
                val plantId = backStackEntry.arguments?.getLong("plantId") ?: 0L
                PhotoTimelineScreen(
                    plantId = plantId,
                    onBack = { navController.popBackStack() }
                )
            }
        }

        // ── 浮动胶囊导航栏 ────────────────────────────────────────
        if (showBottomNav) {
            FloatingNavBar(
                modifier = Modifier
                    .align(Alignment.BottomCenter)
                    .fillMaxWidth()
                    .navigationBarsPadding()
                    .padding(horizontal = 18.dp, vertical = 10.dp),
                currentDestination = currentDestination,
                onNavigate = { screen ->
                    navController.navigate(screen.route) {
                        popUpTo(navController.graph.findStartDestination().id) {
                            saveState = true
                        }
                        launchSingleTop = true
                        restoreState = true
                    }
                }
            )
        }
    }
}

/** 浮动胶囊导航栏（对应原型 .nav-wrap > .nav） */
@Composable
private fun FloatingNavBar(
    modifier: Modifier = Modifier,
    currentDestination: androidx.navigation.NavDestination?,
    onNavigate: (Screen) -> Unit
) {
    Row(
        modifier = modifier
            .shadow(
                elevation = 8.dp,
                shape = RoundedCornerShape(100.dp),
                ambientColor = androidx.compose.ui.graphics.Color(0x388CA578),
                spotColor = androidx.compose.ui.graphics.Color(0x388CA578)
            )
            .background(NavBg, RoundedCornerShape(100.dp))
            .padding(vertical = 12.dp, horizontal = 6.dp),
        horizontalArrangement = Arrangement.SpaceAround,
        verticalAlignment = Alignment.CenterVertically
    ) {
        bottomNavItems.forEach { screen ->
            val selected = currentDestination?.hierarchy
                ?.any { it.route == screen.route } == true

            NavButton(
                screen = screen,
                selected = selected,
                onClick = { onNavigate(screen) }
            )
        }
    }
}

/** 单个导航按钮（图标 + 文字） */
@Composable
private fun NavButton(
    screen: Screen,
    selected: Boolean,
    onClick: () -> Unit
) {
    Column(
        modifier = Modifier
            .clickable(onClick = onClick)
            .padding(horizontal = 14.dp, vertical = 4.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(3.dp)
    ) {
        Icon(
            imageVector = screen.icon,
            contentDescription = screen.label,
            tint = if (selected) GreenDark else MutedColor,
            modifier = Modifier.size(22.dp)
        )
        Text(
            text = screen.label,
            fontSize = 10.sp,
            fontWeight = FontWeight.Medium,
            color = if (selected) GreenDark else MutedColor
        )
    }
}

/** 供各主页面使用的标准顶部 padding（状态栏高度） */
val Modifier.screenTopPadding: Modifier
    get() = this.statusBarsPadding()

/** 供各主页面使用的底部 padding（浮动导航栏高度 ≈ 96dp） */
const val FLOATING_NAV_BOTTOM_PADDING = 96
