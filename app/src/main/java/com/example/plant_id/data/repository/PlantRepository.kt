package com.example.plant_id.data.repository

import com.example.plant_id.data.dao.PlantDao
import com.example.plant_id.data.entity.Plant
import kotlinx.coroutines.flow.Flow

class PlantRepository(private val plantDao: PlantDao) {

    suspend fun insert(plant: Plant): Long = plantDao.insert(plant)

    suspend fun update(plant: Plant) = plantDao.update(plant)

    suspend fun delete(plant: Plant) = plantDao.delete(plant)

    fun getAlivePlants(): Flow<List<Plant>> = plantDao.getAlivePlants()

    fun getArchivedPlants(): Flow<List<Plant>> = plantDao.getArchivedPlants()

    fun getPlantById(id: Long): Flow<Plant?> = plantDao.getPlantById(id)

    suspend fun getPlantByNfcTag(tagId: String): Plant? = plantDao.getPlantByNfcTag(tagId)

    suspend fun getAllNfcTagIds(): List<String> = plantDao.getAllNfcTagIds()

    suspend fun getAllAlivePlantsSnapshot(): List<Plant> = plantDao.getAllAlivePlantsSnapshot()

    suspend fun countAlivePlants(): Int = plantDao.countAlivePlants()
}
