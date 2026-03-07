import Testing
import SwiftData
import Foundation
@testable import PlantID

@Suite("PlantRepository Tests")
struct PlantRepositoryTests {
    private func makeRepo() throws -> (SwiftDataPlantRepository, ModelContainer) {
        let schema = Schema([Plant.self, WateringLog.self, Photo.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: config)
        let ctx = ModelContext(container)
        let repo = SwiftDataPlantRepository(modelContext: ctx)
        return (repo, container)
    }

    @Test("Insert and fetch alive plant")
    func testInsertAndFetchAlive() throws {
        let (repo, _) = try makeRepo()
        let plant = Plant(name: "Monstera", species: "Monstera deliciosa")
        try repo.insert(plant)
        let plants = try repo.getAlivePlants()
        #expect(plants.count == 1)
        #expect(plants[0].name == "Monstera")
    }

    @Test("Get plant by ID")
    func testGetById() throws {
        let (repo, _) = try makeRepo()
        let plant = Plant(name: "Fern")
        try repo.insert(plant)
        let found = try repo.getPlantById(plant.id)
        #expect(found != nil)
        #expect(found?.name == "Fern")
    }

    @Test("Get plant by NFC tag")
    func testGetByNfcTag() throws {
        let (repo, _) = try makeRepo()
        let plant = Plant(name: "Cactus", nfcTagId: "TAG123")
        try repo.insert(plant)
        let found = try repo.getPlantByNfcTag("TAG123")
        #expect(found != nil)
        #expect(found?.name == "Cactus")
    }

    @Test("Archive plant moves to archived list")
    func testArchive() throws {
        let (repo, _) = try makeRepo()
        let plant = Plant(name: "Rose")
        try repo.insert(plant)
        plant.status = "archived"
        plant.archivedAt = Date()
        try repo.update()
        let alive = try repo.getAlivePlants()
        let archived = try repo.getArchivedPlants()
        #expect(alive.isEmpty)
        #expect(archived.count == 1)
    }

    @Test("Delete plant removes from store")
    func testDelete() throws {
        let (repo, _) = try makeRepo()
        let plant = Plant(name: "Palm")
        try repo.insert(plant)
        try repo.delete(plant)
        let plants = try repo.getAlivePlants()
        #expect(plants.isEmpty)
    }

    @Test("Count alive plants")
    func testCount() throws {
        let (repo, _) = try makeRepo()
        try repo.insert(Plant(name: "P1"))
        try repo.insert(Plant(name: "P2"))
        let count = try repo.countAlivePlants()
        #expect(count == 2)
    }

    @Test("Get all NFC tag IDs")
    func testGetAllNfcTagIds() throws {
        let (repo, _) = try makeRepo()
        try repo.insert(Plant(name: "P1", nfcTagId: "A"))
        try repo.insert(Plant(name: "P2", nfcTagId: "B"))
        try repo.insert(Plant(name: "P3", nfcTagId: ""))
        let tags = try repo.getAllNfcTagIds()
        #expect(tags.sorted() == ["A", "B"])
    }
}
