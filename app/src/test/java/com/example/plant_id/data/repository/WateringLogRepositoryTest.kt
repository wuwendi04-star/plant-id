package com.example.plant_id.data.repository

import com.example.plant_id.data.dao.WateringLogDao
import com.example.plant_id.data.entity.WateringLog
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

class WateringLogRepositoryTest {

    private lateinit var wateringLogDao: WateringLogDao
    private lateinit var repository: WateringLogRepository

    private val testLog = WateringLog(id = 1L, plantId = 10L, wateredAt = 1000L)

    @Before
    fun setUp() {
        wateringLogDao = mockk()
        repository = WateringLogRepository(wateringLogDao)
    }

    @Test
    fun `insert delegates to dao and returns id`() = runTest {
        coEvery { wateringLogDao.insert(testLog) } returns 1L

        val result = repository.insert(testLog)

        coVerify(exactly = 1) { wateringLogDao.insert(testLog) }
        assertEquals(1L, result)
    }

    @Test
    fun `delete delegates to dao`() = runTest {
        coEvery { wateringLogDao.delete(testLog) } returns Unit

        repository.delete(testLog)

        coVerify(exactly = 1) { wateringLogDao.delete(testLog) }
    }

    @Test
    fun `getLogsByPlant returns flow from dao`() = runTest {
        val expected = listOf(testLog)
        every { wateringLogDao.getLogsByPlant(10L) } returns flowOf(expected)

        val result = repository.getLogsByPlant(10L).first()

        verify(exactly = 1) { wateringLogDao.getLogsByPlant(10L) }
        assertEquals(expected, result)
    }

    @Test
    fun `getLastWatering returns log from dao`() = runTest {
        coEvery { wateringLogDao.getLastWatering(10L) } returns testLog

        val result = repository.getLastWatering(10L)

        coVerify(exactly = 1) { wateringLogDao.getLastWatering(10L) }
        assertEquals(testLog, result)
    }

    @Test
    fun `getLastWatering returns null when no watering logs`() = runTest {
        coEvery { wateringLogDao.getLastWatering(99L) } returns null

        val result = repository.getLastWatering(99L)

        assertNull(result)
    }

    @Test
    fun `countByPlant delegates to dao`() = runTest {
        coEvery { wateringLogDao.countByPlant(10L) } returns 3

        val result = repository.countByPlant(10L)

        coVerify(exactly = 1) { wateringLogDao.countByPlant(10L) }
        assertEquals(3, result)
    }

    @Test
    fun `countAll delegates to dao`() = runTest {
        coEvery { wateringLogDao.countAll() } returns 42

        val result = repository.countAll()

        coVerify(exactly = 1) { wateringLogDao.countAll() }
        assertEquals(42, result)
    }
}
