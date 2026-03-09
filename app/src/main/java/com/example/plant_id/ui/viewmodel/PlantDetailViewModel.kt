package com.example.plant_id.ui.viewmodel

import android.app.Application
import android.content.Context
import android.net.Uri
import android.os.Environment
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.core.content.FileProvider
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import com.example.plant_id.data.database.PlantDatabase
import com.example.plant_id.data.entity.Photo
import com.example.plant_id.data.entity.Plant
import com.example.plant_id.data.entity.WateringLog
import com.example.plant_id.data.repository.PhotoRepository
import com.example.plant_id.data.repository.PlantRepository
import com.example.plant_id.data.repository.WateringLogRepository
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch
import java.io.File

class PlantDetailViewModel(
    private val plantRepository: PlantRepository,
    private val wateringLogRepository: WateringLogRepository,
    private val photoRepository: PhotoRepository,
    application: Application
) : AndroidViewModel(application) {

    private var _plantId: Long = -1L

    var plant by mutableStateOf<Plant?>(null)
        private set

    var wateringLogs by mutableStateOf<List<WateringLog>>(emptyList())
        private set

    var photos by mutableStateOf<List<Photo>>(emptyList())
        private set

    var lastWateredDaysAgo by mutableIntStateOf(-1)
        private set

    var daysKept by mutableIntStateOf(0)
        private set

    var isAddingWatering by mutableStateOf(false)
        private set

    var pendingPhotoFilePath by mutableStateOf<String?>(null)
        private set

    var showWateringSuccess by mutableStateOf(false)
        private set

    fun loadPlant(id: Long) {
        if (_plantId == id) return
        _plantId = id

        viewModelScope.launch {
            plantRepository.getPlantById(id).collect { p ->
                plant = p
                p?.let {
                    daysKept = ((System.currentTimeMillis() - it.acquiredDate) / 86_400_000L)
                        .toInt().coerceAtLeast(0)
                }
            }
        }

        viewModelScope.launch {
            wateringLogRepository.getLogsByPlant(id).collect { logs ->
                wateringLogs = logs
                val last = logs.firstOrNull()
                lastWateredDaysAgo = if (last != null) {
                    ((System.currentTimeMillis() - last.wateredAt) / 86_400_000L)
                        .toInt().coerceAtLeast(0)
                } else {
                    -1
                }
            }
        }

        viewModelScope.launch {
            photoRepository.getPhotosByPlant(id).collect { list ->
                photos = list
            }
        }
    }

    fun prepareCameraUri(context: Context): Uri? {
        val id = _plantId
        if (id < 0) return null
        return try {
            val photoDir = File(
                context.getExternalFilesDir(Environment.DIRECTORY_PICTURES),
                "plants"
            )
            photoDir.mkdirs()
            val file = File(photoDir, "plant_${id}_${System.currentTimeMillis()}.jpg")
            pendingPhotoFilePath = file.absolutePath
            FileProvider.getUriForFile(
                context,
                "${context.packageName}.fileprovider",
                file
            )
        } catch (e: Exception) {
            null
        }
    }

    fun saveWateringWithPhoto() {
        val path = pendingPhotoFilePath ?: return addWatering()
        val id = _plantId
        if (id < 0 || isAddingWatering) return
        pendingPhotoFilePath = null
        isAddingWatering = true
        viewModelScope.launch {
            photoRepository.insert(Photo(plantId = id, filePath = path))
            wateringLogRepository.insert(WateringLog(plantId = id, photoPath = path))
            isAddingWatering = false
            showWateringSuccess = true
        }
    }

    fun savePhotoOnly() {
        val path = pendingPhotoFilePath ?: return
        val id = _plantId
        if (id < 0) return
        pendingPhotoFilePath = null
        viewModelScope.launch {
            photoRepository.insert(Photo(plantId = id, filePath = path))
        }
    }

    fun addWatering(onSuccess: () -> Unit = {}) {
        val id = _plantId
        if (id < 0 || isAddingWatering) return
        isAddingWatering = true
        viewModelScope.launch {
            wateringLogRepository.insert(WateringLog(plantId = id))
            isAddingWatering = false
            showWateringSuccess = true
            onSuccess()
        }
    }

    fun dismissWateringSuccess() {
        showWateringSuccess = false
    }

    fun archivePlant(onSuccess: () -> Unit = {}) {
        val current = plant ?: return
        viewModelScope.launch {
            plantRepository.update(
                current.copy(
                    status = "archived",
                    archivedAt = System.currentTimeMillis()
                )
            )
            onSuccess()
        }
    }

    fun deletePlant(onSuccess: () -> Unit = {}) {
        val current = plant ?: return
        viewModelScope.launch {
            // Delete photo files from disk before DB cascade removes the records
            val photosToDelete = photoRepository.getPhotosByPlant(current.id).first()
            photosToDelete.forEach { photo ->
                File(photo.filePath).takeIf { it.exists() }?.delete()
            }
            // Deleting the plant cascades watering_logs and photos rows in DB
            plantRepository.delete(current)
            onSuccess()
        }
    }

    companion object {
        fun factory(application: Application): ViewModelProvider.Factory =
            object : ViewModelProvider.Factory {
                private val db = PlantDatabase.getInstance(application)
                private val plantRepo = PlantRepository(db.plantDao())
                private val wateringRepo = WateringLogRepository(db.wateringLogDao())
                private val photoRepo = PhotoRepository(db.photoDao())
                @Suppress("UNCHECKED_CAST")
                override fun <T : ViewModel> create(modelClass: Class<T>): T =
                    PlantDetailViewModel(plantRepo, wateringRepo, photoRepo, application) as T
            }
    }
}
