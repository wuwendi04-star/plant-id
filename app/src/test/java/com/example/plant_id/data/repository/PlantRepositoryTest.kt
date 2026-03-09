package com.example.plant_id.data.repository

import com.example.plant_id.data.dao.PlantDao
import com.example.plant_id.data.entity.Plant
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

class PlantRepositoryTest {

    private lateinit var plantDao: PlantDao
    private lateinit var repository: PlantRepository

    private val testPlant = Plant(id = 1L, name = "Monstera", wateringIntervalDays = 7)

    @Before
    fun setUp() {
        plantDao = mockk()
        repository = PlantRepository(plantDao)
    }

    @Test
    fun `insert delegates to dao and returns id`() = runTest {
        coEvery { plantDao.insert(testPlant) } returns 1L

        val result = repository.insert(testPlant)

        coVerify(exactly = 1) { plantDao.insert(testPlant) }
        assertEquals(1L, result)
    }

    @Test
    fun `update delegates to dao`() = runTest {
        coEvery { plantDao.update(testPlant) } returns Unit

        repository.update(testPlant)

        coVerify(exactly = 1) { plantDao.update(testPlant) }
    }

    @Test
    fun `delete delegates to dao`() = runTest {
        coEvery { plantDao.delete(testPlant) } returns Unit

        repository.delete(testPlant)

        coVerify(exactly = 1) { plantDao.delete(testPlant) }
    }

    @Test
    fun `getAlivePlants returns flow from dao`() = runTest {
        val expected = listOf(testPlant)
        every { plantDao.getAlivePlants() } returns flowOf(expected)

        val result = repository.getAlivePlants().first()

        verify(exactly = 1) { plantDao.getAlivePlants() }
        assertEquals(expected, result)
    }

    @Test
    fun `getArchivedPlants returns flow from dao`() = runTest {
        val archived = testPlant.copy(status = "archived")
        every { plantDao.getArchivedPlants() } returns flowOf(listOf(archived))

        val result = repository.getArchivedPlants().first()

        verify(exactly = 1) { plantDao.getArchivedPlants() }
        assertEquals(listOf(archived), result)
    }

    @Test
    fun `getPlantById returns flow from dao`() = runTest {
        every { plantDao.getPlantById(1L) } returns flowOf(testPlant)

        val result = repository.getPlantById(1L).first()

        verify(exactly = 1) { plantDao.getPlantById(1L) }
        assertEquals(testPlant, result)
    }

    @Test
    fun `getPlantById returns null flow when plant not found`() = runTest {
        every { plantDao.getPlantById(99L) } returns flowOf(null)

        val result = repository.getPlantById(99L).first()

        assertNull(result)
    }

    @Test
    fun `getPlantByNfcTag delegates to dao`() = runTest {
        coEvery { plantDao.getPlantByNfcTag("abc123") } returns testPlant

        val result = repository.getPlantByNfcTag("abc123")

        coVerify(exactly = 1) { plantDao.getPlantByNfcTag("abc123") }
        assertEquals(testPlant, result)
    }

    @Test
    fun `getAllNfcTagIds delegates to dao`() = runTest {
        val tags = listOf("abc123", "def456")
        coEvery { plantDao.getAllNfcTagIds() } returns tags

        val result = repository.getAllNfcTagIds()

        coVerify(exactly = 1) { plantDao.getAllNfcTagIds() }
        assertEquals(tags, result)
    }

    @Test
    fun `getAllAlivePlantsSnapshot delegates to dao`() = runTest {
        coEvery { plantDao.getAllAlivePlantsSnapshot() } returns listOf(testPlant)

        val result = repository.getAllAlivePlantsSnapshot()

        coVerify(exactly = 1) { plantDao.getAllAlivePlantsSnapshot() }
        assertEquals(listOf(testPlant), result)
    }

    @Test
    fun `countAlivePlants delegates to dao`() = runTest {
        coEvery { plantDao.countAlivePlants() } returns 5

        val result = repository.countAlivePlants()

        coVerify(exactly = 1) { plantDao.countAlivePlants() }
        assertEquals(5, result)
    }
}
