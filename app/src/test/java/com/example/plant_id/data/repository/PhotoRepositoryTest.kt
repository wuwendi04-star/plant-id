package com.example.plant_id.data.repository

import com.example.plant_id.data.dao.PhotoDao
import com.example.plant_id.data.entity.Photo
import io.mockk.coEvery
import io.mockk.coVerify
import io.mockk.every
import io.mockk.mockk
import io.mockk.verify
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.test.runTest
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Before
import org.junit.Test

class PhotoRepositoryTest {

    private lateinit var photoDao: PhotoDao
    private lateinit var repository: PhotoRepository

    private val testPhoto = Photo(id = 1L, plantId = 10L, filePath = "/data/photos/plant_10.jpg")

    @Before
    fun setUp() {
        photoDao = mockk()
        repository = PhotoRepository(photoDao)
    }

    @Test
    fun `insert delegates to dao and returns id`() = runTest {
        coEvery { photoDao.insert(testPhoto) } returns 1L

        val result = repository.insert(testPhoto)

        coVerify(exactly = 1) { photoDao.insert(testPhoto) }
        assertEquals(1L, result)
    }

    @Test
    fun `delete delegates to dao`() = runTest {
        coEvery { photoDao.delete(testPhoto) } returns Unit

        repository.delete(testPhoto)

        coVerify(exactly = 1) { photoDao.delete(testPhoto) }
    }

    @Test
    fun `getPhotosByPlant returns flow from dao`() = runTest {
        val expected = listOf(testPhoto)
        every { photoDao.getPhotosByPlant(10L) } returns flowOf(expected)

        val result = repository.getPhotosByPlant(10L).first()

        verify(exactly = 1) { photoDao.getPhotosByPlant(10L) }
        assertEquals(expected, result)
    }

    @Test
    fun `getLatestPhoto returns photo from dao`() = runTest {
        coEvery { photoDao.getLatestPhoto(10L) } returns testPhoto

        val result = repository.getLatestPhoto(10L)

        coVerify(exactly = 1) { photoDao.getLatestPhoto(10L) }
        assertEquals(testPhoto, result)
    }

    @Test
    fun `getLatestPhoto returns null when no photos`() = runTest {
        coEvery { photoDao.getLatestPhoto(99L) } returns null

        val result = repository.getLatestPhoto(99L)

        assertNull(result)
    }

    @Test
    fun `countAll delegates to dao`() = runTest {
        coEvery { photoDao.countAll() } returns 15

        val result = repository.countAll()

        coVerify(exactly = 1) { photoDao.countAll() }
        assertEquals(15, result)
    }
}
