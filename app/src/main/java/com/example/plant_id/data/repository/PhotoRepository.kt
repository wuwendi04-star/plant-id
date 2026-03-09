package com.example.plant_id.data.repository

import com.example.plant_id.data.dao.PhotoDao
import com.example.plant_id.data.entity.Photo
import kotlinx.coroutines.flow.Flow

class PhotoRepository(private val photoDao: PhotoDao) {

    suspend fun insert(photo: Photo): Long = photoDao.insert(photo)

    suspend fun delete(photo: Photo) = photoDao.delete(photo)

    fun getPhotosByPlant(plantId: Long): Flow<List<Photo>> = photoDao.getPhotosByPlant(plantId)

    suspend fun getLatestPhoto(plantId: Long): Photo? = photoDao.getLatestPhoto(plantId)

    suspend fun countAll(): Int = photoDao.countAll()
}
