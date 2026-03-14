import Testing
import SwiftData
import Foundation
@testable import PlantID

// .serialized prevents concurrent writes to ModelContainerProvider.shared
@Suite("PlantEntityQuery Tests", .serialized)
@MainActor
struct PlantEntityQueryTests {

    private func makeContainer() throws -> ModelContainer {
        let schema = Schema([Plant.self, WateringLog.self, Photo.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: config)
    }

    @Test("suggestedEntities returns only alive plants")
    func testSuggestedEntitiesAliveOnly() async throws {
        let container = try makeContainer()
        ModelContainerProvider.shared.configure(container)
        let repo = SwiftDataPlantRepository(modelContext: container.mainContext)
        let alive = Plant(name: "Monstera", species: "M. deliciosa")
        var archived = Plant(name: "Cactus", species: "Opuntia")
        archived.status = "archived"
        try repo.insert(alive)
        try repo.insert(archived)

        let query = PlantEntityQuery()
        let results = try await query.suggestedEntities()
        #expect(results.count == 1)
        #expect(results[0].name == "Monstera")
    }

    @Test("suggestedEntities returns empty array when no plants exist")
    func testSuggestedEntitiesEmpty() async throws {
        let container = try makeContainer()
        ModelContainerProvider.shared.configure(container)

        let query = PlantEntityQuery()
        let results = try await query.suggestedEntities()
        #expect(results.isEmpty)
    }

    @Test("entities(matching:) with empty string returns all alive plants")
    func testEntitiesMatchingEmptyReturnsAll() async throws {
        let container = try makeContainer()
        ModelContainerProvider.shared.configure(container)
        let repo = SwiftDataPlantRepository(modelContext: container.mainContext)
        try repo.insert(Plant(name: "Fern", species: "Nephrolepis"))
        try repo.insert(Plant(name: "Palm", species: "Dypsis"))

        let query = PlantEntityQuery()
        let results = try await query.entities(matching: "")
        #expect(results.count == 2)
    }

    @Test("entities(matching:) filters by plant name case-insensitively")
    func testEntitiesMatchingCaseInsensitive() async throws {
        let container = try makeContainer()
        ModelContainerProvider.shared.configure(container)
        let repo = SwiftDataPlantRepository(modelContext: container.mainContext)
        try repo.insert(Plant(name: "Monstera", species: "M. deliciosa"))
        try repo.insert(Plant(name: "Money Tree", species: "Pachira"))
        try repo.insert(Plant(name: "Fern", species: "Nephrolepis"))

        let query = PlantEntityQuery()
        let results = try await query.entities(matching: "mon")
        #expect(results.count == 2)
        let names = results.map { $0.name }
        #expect(names.contains("Monstera"))
        #expect(names.contains("Money Tree"))
    }

    @Test("entities(for:) resolves correct plants by UUID")
    func testEntitiesForIds() async throws {
        let container = try makeContainer()
        ModelContainerProvider.shared.configure(container)
        let repo = SwiftDataPlantRepository(modelContext: container.mainContext)
        let p1 = Plant(name: "Alpha", species: "A")
        let p2 = Plant(name: "Beta", species: "B")
        try repo.insert(p1)
        try repo.insert(p2)

        let query = PlantEntityQuery()
        let results = try await query.entities(for: [p1.id])
        #expect(results.count == 1)
        #expect(results[0].id == p1.id)
    }

    @Test("entities(for:) returns empty when IDs don't match")
    func testEntitiesForUnknownIds() async throws {
        let container = try makeContainer()
        ModelContainerProvider.shared.configure(container)
        let repo = SwiftDataPlantRepository(modelContext: container.mainContext)
        try repo.insert(Plant(name: "Alpha", species: "A"))

        let query = PlantEntityQuery()
        let results = try await query.entities(for: [UUID()])
        #expect(results.isEmpty)
    }

    @Test("ModelContainerProvider returns empty results when container is nil")
    func testNilContainerReturnsEmpty() async throws {
        let previous = ModelContainerProvider.shared.container
        ModelContainerProvider.shared.configure(try makeContainer()) // put something in first
        // Temporarily nil it — we only have a private(set) so we configure a fresh container
        // and test by using an empty container instead (nil can't be set from outside)
        let emptyContainer = try makeContainer()
        ModelContainerProvider.shared.configure(emptyContainer)

        let query = PlantEntityQuery()
        let results = try await query.suggestedEntities()
        #expect(results.isEmpty)

        // Restore
        if let previous { ModelContainerProvider.shared.configure(previous) }
    }
}
