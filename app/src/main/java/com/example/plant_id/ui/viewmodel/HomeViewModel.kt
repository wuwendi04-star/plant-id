package com.example.plant_id.ui.viewmodel

import android.app.Application
import android.content.Context
import android.util.Log
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import com.example.plant_id.data.database.PlantDatabase
import com.example.plant_id.data.entity.Plant
import com.example.plant_id.data.repository.PlantRepository
import com.example.plant_id.data.repository.WateringLogRepository
import com.example.plant_id.ui.components.WateringUrgency
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch

class HomeViewModel(
    private val plantRepository: PlantRepository,
    private val wateringLogRepository: WateringLogRepository,
    application: Application
) : AndroidViewModel(application) {

    /** 当前选中的 Tab（0=存活中，1=已归档） */
    var selectedTab by mutableIntStateOf(0)

    /** 浇水状态映射表：plantId → WateringUrgency */
    var wateringStatusMap by mutableStateOf<Map<Long, WateringUrgency>>(emptyMap())
        private set

    /** 存活中的植物列表（实时） */
    val alivePlants: StateFlow<List<Plant>> = plantRepository.getAlivePlants()
        .stateIn(
            scope = viewModelScope,
            started = SharingStarted.WhileSubscribed(5_000),
            initialValue = emptyList()
        )

    /** 已归档的植物列表（实时） */
    val archivedPlants: StateFlow<List<Plant>> = plantRepository.getArchivedPlants()
        .stateIn(
            scope = viewModelScope,
            started = SharingStarted.WhileSubscribed(5_000),
            initialValue = emptyList()
        )

    init {
        val prefs = application.getSharedPreferences("app_prefs", Context.MODE_PRIVATE)
        val seeded = prefs.getBoolean("sample_data_seeded", false)
        if (!seeded) {
            viewModelScope.launch {
                seedSampleData()
                prefs.edit().putBoolean("sample_data_seeded", true).apply()
            }
        }

        viewModelScope.launch {
            plantRepository.getAlivePlants().collect { plants ->
                val now = System.currentTimeMillis()
                val statusMap = mutableMapOf<Long, WateringUrgency>()

                plants.forEach { plant ->
                    val last = try {
                        wateringLogRepository.getLastWatering(plant.id)
                    } catch (e: Exception) {
                        Log.w("HomeViewModel", "Failed to fetch last watering for plant ${plant.id}", e)
                        null
                    }

                    val daysSince = if (last != null) {
                        ((now - last.wateredAt) / 86_400_000L).toInt().coerceAtLeast(0)
                    } else {
                        -1
                    }

                    val urgency = when {
                        daysSince < 0 -> WateringUrgency.OK
                        daysSince > plant.wateringIntervalDays -> WateringUrgency.OVERDUE
                        daysSince == plant.wateringIntervalDays -> WateringUrgency.DUE_TODAY
                        else -> WateringUrgency.OK
                    }

                    statusMap[plant.id] = urgency
                }

                wateringStatusMap = statusMap
            }
        }
    }

    private suspend fun seedSampleData() {
        listOf(
            Plant(
                name = "绿萝",
                species = "魔鬼藤",
                wateringIntervalDays = 5,
                iconName = "pothos",
                notes = "适合室内散射光，土干透后再浇"
            ),
            Plant(
                name = "仙人掌",
                species = "金琥",
                wateringIntervalDays = 21,
                iconName = "cactus",
                notes = "喜强光，极耐旱，冬季减少浇水"
            ),
            Plant(
                name = "虎皮兰",
                species = "虎尾兰属",
                wateringIntervalDays = 14,
                iconName = "haworthia",
                notes = "耐阴耐旱，新手首选，忌积水"
            ),
            Plant(
                name = "龟背竹",
                species = "天南星科",
                wateringIntervalDays = 7,
                iconName = "monstera",
                notes = "喜温暖湿润，夏季保持土壤微湿"
            ),
        ).forEach { plantRepository.insert(it) }
    }

    companion object {
        fun factory(application: Application): ViewModelProvider.Factory =
            object : ViewModelProvider.Factory {
                private val db = PlantDatabase.getInstance(application)
                private val plantRepo = PlantRepository(db.plantDao())
                private val wateringRepo = WateringLogRepository(db.wateringLogDao())
                @Suppress("UNCHECKED_CAST")
                override fun <T : ViewModel> create(modelClass: Class<T>): T =
                    HomeViewModel(plantRepo, wateringRepo, application) as T
            }
    }
}
