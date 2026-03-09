package com.example.plant_id.ui.viewmodel

import android.app.Application
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableLongStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import com.example.plant_id.data.database.PlantDatabase
import com.example.plant_id.data.entity.Plant
import com.example.plant_id.data.repository.PlantRepository
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch

class CreatePlantViewModel(
    private val plantRepository: PlantRepository,
    application: Application
) : AndroidViewModel(application) {

    var iconName by mutableStateOf("monstera")
    var name by mutableStateOf("")
    var species by mutableStateOf("")
    var acquiredDate by mutableLongStateOf(System.currentTimeMillis())
    var wateringIntervalDays by mutableIntStateOf(7)
    var notes by mutableStateOf("")
    var nfcTagId by mutableStateOf("")
    var status by mutableStateOf("alive")

    var editingPlantId: Long? = null
        private set

    var isLoading by mutableStateOf(false)
        private set

    fun loadPlant(id: Long) {
        if (editingPlantId == id) return
        editingPlantId = id
        isLoading = true
        viewModelScope.launch {
            val plant = plantRepository.getPlantById(id).first()
            plant?.let {
                iconName = it.iconName
                name = it.name
                species = it.species
                acquiredDate = it.acquiredDate
                wateringIntervalDays = it.wateringIntervalDays
                notes = it.notes
                status = it.status
                nfcTagId = it.nfcTagId
            }
            isLoading = false
        }
    }

    fun prefillNfcTag(tagId: String) {
        if (nfcTagId.isBlank()) nfcTagId = tagId
    }

    fun createPlant(onSuccess: () -> Unit) {
        viewModelScope.launch {
            plantRepository.insert(
                Plant(
                    iconName = iconName,
                    name = name.trim(),
                    species = species.trim(),
                    acquiredDate = acquiredDate,
                    wateringIntervalDays = wateringIntervalDays,
                    notes = notes.trim(),
                    nfcTagId = nfcTagId.trim()
                )
            )
            onSuccess()
        }
    }

    fun updatePlant(onSuccess: () -> Unit) {
        val id = editingPlantId ?: return
        viewModelScope.launch {
            val existing = plantRepository.getPlantById(id).first() ?: return@launch
            plantRepository.update(
                existing.copy(
                    iconName = iconName,
                    name = name.trim(),
                    species = species.trim(),
                    acquiredDate = acquiredDate,
                    wateringIntervalDays = wateringIntervalDays,
                    notes = notes.trim(),
                    status = status,
                    nfcTagId = nfcTagId.trim()
                )
            )
            onSuccess()
        }
    }

    fun archivePlant(onSuccess: () -> Unit) {
        val id = editingPlantId ?: return
        viewModelScope.launch {
            val existing = plantRepository.getPlantById(id).first() ?: return@launch
            plantRepository.update(existing.copy(status = "archived"))
            onSuccess()
        }
    }

    companion object {
        fun factory(application: Application): ViewModelProvider.Factory =
            object : ViewModelProvider.Factory {
                private val plantRepo = PlantRepository(PlantDatabase.getInstance(application).plantDao())
                @Suppress("UNCHECKED_CAST")
                override fun <T : ViewModel> create(modelClass: Class<T>): T =
                    CreatePlantViewModel(plantRepo, application) as T
            }
    }
}
