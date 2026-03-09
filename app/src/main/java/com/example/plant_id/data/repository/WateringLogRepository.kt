package com.example.plant_id.data.repository

import com.example.plant_id.data.dao.WateringLogDao
import com.example.plant_id.data.entity.WateringLog
import kotlinx.coroutines.flow.Flow

class WateringLogRepository(private val wateringLogDao: WateringLogDao) {

    suspend fun insert(log: WateringLog): Long = wateringLogDao.insert(log)

    suspend fun delete(log: WateringLog) = wateringLogDao.delete(log)

    fun getLogsByPlant(plantId: Long): Flow<List<WateringLog>> =
        wateringLogDao.getLogsByPlant(plantId)

    suspend fun getLastWatering(plantId: Long): WateringLog? =
        wateringLogDao.getLastWatering(plantId)

    suspend fun countByPlant(plantId: Long): Int = wateringLogDao.countByPlant(plantId)

    suspend fun countAll(): Int = wateringLogDao.countAll()
}
