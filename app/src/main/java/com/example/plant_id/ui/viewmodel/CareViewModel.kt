package com.example.plant_id.ui.viewmodel

import android.app.Application
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import com.example.plant_id.data.database.PlantDatabase
import com.example.plant_id.data.entity.Plant
import com.example.plant_id.data.entity.WateringLog
import com.example.plant_id.data.repository.PlantRepository
import com.example.plant_id.data.repository.WateringLogRepository
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch

data class PlantCareItem(
    val plant: Plant,
    val daysSinceWatering: Int,
    val daysUntilDue: Int
) {
    val isOverdue: Boolean get() = daysUntilDue < 0
    val isDueToday: Boolean get() = daysUntilDue == 0
    val isUpcoming: Boolean get() = daysUntilDue in 1..2
    val needsAttention: Boolean get() = isOverdue || isDueToday
}

class CareViewModel(
    private val plantRepository: PlantRepository,
    private val wateringLogRepository: WateringLogRepository,
    application: Application
) : AndroidViewModel(application) {

    var careItems by mutableStateOf<List<PlantCareItem>>(emptyList())
        private set

    var isLoading by mutableStateOf(true)
        private set

    init {
        loadData()
    }

    private fun loadData() {
        viewModelScope.launch {
            plantRepository.getAlivePlants().collect { plants ->
                computeCareItems(plants)
                isLoading = false
            }
        }
    }

    private suspend fun computeCareItems(plants: List<Plant>) {
        val now = System.currentTimeMillis()
        val items = plants.map { plant ->
            val last = wateringLogRepository.getLastWatering(plant.id)
            val daysSince = if (last != null) {
                ((now - last.wateredAt) / 86_400_000L).toInt().coerceAtLeast(0)
            } else {
                -1
            }
            val daysUntilDue = if (daysSince < 0) {
                -(plant.wateringIntervalDays + 1)
            } else {
                plant.wateringIntervalDays - daysSince
            }
            PlantCareItem(plant, daysSince, daysUntilDue)
        }
        careItems = items.sortedBy { it.daysUntilDue }
    }

    fun waterPlant(plantId: Long, onSuccess: () -> Unit = {}) {
        viewModelScope.launch {
            wateringLogRepository.insert(WateringLog(plantId = plantId))
            val plants = plantRepository.getAlivePlants().first()
            computeCareItems(plants)
            onSuccess()
        }
    }

    companion object {
        fun factory(application: Application): ViewModelProvider.Factory =
            object : ViewModelProvider.Factory {
                private val db = PlantDatabase.getInstance(application)
                private val plantRepo = PlantRepository(db.plantDao())
                private val wateringRepo = WateringLogRepository(db.wateringLogDao())
                @Suppress("UNCHECKED_CAST")
                override fun <T : ViewModel> create(modelClass: Class<T>): T =
                    CareViewModel(plantRepo, wateringRepo, application) as T
            }
    }
}
