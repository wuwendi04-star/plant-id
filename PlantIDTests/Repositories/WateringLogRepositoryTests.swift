import Testing
import SwiftData
import Foundation
@testable import PlantID

@Suite("WateringLogRepository Tests")
@MainActor
struct WateringLogRepositoryTests {
    private func makeRepos() throws -> (SwiftDataWateringLogRepository, SwiftDataPlantRepository, ModelContainer) {
        let schema = Schema([Plant.self, WateringLog.self, Photo.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: config)
        let ctx = ModelContext(container)
        return (
            SwiftDataWateringLogRepository(modelContext: ctx),
            SwiftDataPlantRepository(modelContext: ctx),
            container
        )
    }

    @Test("Insert and fetch logs by plant")
    func testInsertAndFetch() throws {
        let (logRepo, plantRepo, _) = try makeRepos()
        let plant = Plant(name: "Monstera")
        try plantRepo.insert(plant)

        let log = WateringLog(plant: plant, wateredAt: Date())
        try logRepo.insert(log)

        let logs = try logRepo.getLogsByPlant(plant.id)
        #expect(logs.count == 1)
    }

    @Test("Get last watering")
    func testGetLastWatering() throws {
        let (logRepo, plantRepo, _) = try makeRepos()
        let plant = Plant(name: "Fern")
        try plantRepo.insert(plant)

        let old = WateringLog(plant: plant, wateredAt: Date().addingTimeInterval(-86400))
        let recent = WateringLog(plant: plant, wateredAt: Date())
        try logRepo.insert(old)
        try logRepo.insert(recent)

        let last = try logRepo.getLastWatering(plantId: plant.id)
        #expect(last != nil)
        #expect(last!.wateredAt >= old.wateredAt)
    }

    @Test("Count by plant")
    func testCountByPlant() throws {
        let (logRepo, plantRepo, _) = try makeRepos()
        let plant = Plant(name: "Palm")
        try plantRepo.insert(plant)
        try logRepo.insert(WateringLog(plant: plant))
        try logRepo.insert(WateringLog(plant: plant))
        let count = try logRepo.countByPlant(plant.id)
        #expect(count == 2)
    }

    @Test("Delete log")
    func testDelete() throws {
        let (logRepo, plantRepo, _) = try makeRepos()
        let plant = Plant(name: "Cactus")
        try plantRepo.insert(plant)
        let log = WateringLog(plant: plant)
        try logRepo.insert(log)
        try logRepo.delete(log)
        let logs = try logRepo.getLogsByPlant(plant.id)
        #expect(logs.isEmpty)
    }

    @Test("Count all logs")
    func testCountAll() throws {
        let (logRepo, plantRepo, _) = try makeRepos()
        let p1 = Plant(name: "P1")
        let p2 = Plant(name: "P2")
        try plantRepo.insert(p1)
        try plantRepo.insert(p2)
        try logRepo.insert(WateringLog(plant: p1))
        try logRepo.insert(WateringLog(plant: p2))
        try logRepo.insert(WateringLog(plant: p2))
        let total = try logRepo.countAll()
        #expect(total == 3)
    }
}
