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
import com.example.plant_id.data.repository.PlantRepository
import kotlinx.coroutines.launch

sealed class NfcNavEvent {
    data class GoToDetail(val plantId: Long) : NfcNavEvent()
    data class GoToCreate(val nfcTagId: String) : NfcNavEvent()
    data class TagOrphaned(val nfcTagId: String) : NfcNavEvent()
    object None : NfcNavEvent()
}

class NfcViewModel(
    private val plantRepository: PlantRepository,
    application: Application
) : AndroidViewModel(application) {

    private val tagLock = Any()
    private var _boundTagIds: Set<String> = emptySet()

    init {
        viewModelScope.launch {
            val ids = plantRepository.getAllNfcTagIds()
            synchronized(tagLock) { _boundTagIds = ids.toHashSet() }
        }
    }

    fun isTagBound(tagId: String): Boolean = synchronized(tagLock) { tagId in _boundTagIds }

    var lastTagId by mutableStateOf<String?>(null)
        private set

    var navEvent by mutableStateOf<NfcNavEvent>(NfcNavEvent.None)
        private set

    var allowGoToCreate by mutableStateOf(false)
        private set

    var showNfcSuccessDialog by mutableStateOf(false)
        private set

    fun setCreateMode(enabled: Boolean) {
        allowGoToCreate = enabled
    }

    fun showSuccessDialog() {
        showNfcSuccessDialog = true
    }

    fun hideSuccessDialog() {
        showNfcSuccessDialog = false
    }

    fun processTag(tagId: String) {
        lastTagId = tagId
        viewModelScope.launch {
            val plant = plantRepository.getPlantByNfcTag(tagId)
            when {
                plant != null -> {
                    markTagBound(tagId)
                    navEvent = NfcNavEvent.GoToDetail(plant.id)
                }
                tagId in synchronized(tagLock) { _boundTagIds } -> {
                    synchronized(tagLock) { _boundTagIds = _boundTagIds - tagId }
                    navEvent = NfcNavEvent.TagOrphaned(tagId)
                }
                allowGoToCreate -> navEvent = NfcNavEvent.GoToCreate(tagId)
                else -> navEvent = NfcNavEvent.None
            }
        }
    }

    private fun markTagBound(tagId: String) {
        synchronized(tagLock) {
            if (tagId !in _boundTagIds) _boundTagIds = _boundTagIds + tagId
        }
    }

    fun consumeNavEvent() {
        navEvent = NfcNavEvent.None
    }

    fun navigateToPlant(plantId: Long) {
        navEvent = NfcNavEvent.GoToDetail(plantId)
    }

    companion object {
        fun factory(application: Application): ViewModelProvider.Factory =
            object : ViewModelProvider.Factory {
                private val plantRepo = PlantRepository(PlantDatabase.getInstance(application).plantDao())
                @Suppress("UNCHECKED_CAST")
                override fun <T : ViewModel> create(modelClass: Class<T>): T =
                    NfcViewModel(plantRepo, application) as T
            }
    }
}
