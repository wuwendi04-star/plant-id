import SwiftData
import Foundation

@MainActor
final class SwiftDataPlantRepository: PlantRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func insert(_ plant: Plant) throws {
        modelContext.insert(plant)
        try modelContext.save()
    }

    func update() throws {
        try modelContext.save()
    }

    func delete(_ plant: Plant) throws {
        modelContext.delete(plant)
        try modelContext.save()
    }

    func getAlivePlants() throws -> [Plant] {
        var descriptor = FetchDescriptor<Plant>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        descriptor.predicate = #Predicate { $0.status != "archived" }
        return try modelContext.fetch(descriptor)
    }

    func getArchivedPlants() throws -> [Plant] {
        var descriptor = FetchDescriptor<Plant>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        descriptor.predicate = #Predicate { $0.status == "archived" }
        return try modelContext.fetch(descriptor)
    }

    func getPlantById(_ id: UUID) throws -> Plant? {
        var descriptor = FetchDescriptor<Plant>()
        descriptor.predicate = #Predicate { $0.id == id }
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }

    func getPlantByNfcTag(_ tagId: String) throws -> Plant? {
        var descriptor = FetchDescriptor<Plant>()
        descriptor.predicate = #Predicate { $0.nfcTagId == tagId }
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }

    func getAllNfcTagIds() throws -> [String] {
        var descriptor = FetchDescriptor<Plant>()
        descriptor.predicate = #Predicate { $0.nfcTagId != "" }
        return try modelContext.fetch(descriptor).map(\.nfcTagId)
    }

    func getAllAlivePlantsSnapshot() throws -> [Plant] {
        var descriptor = FetchDescriptor<Plant>()
        descriptor.predicate = #Predicate { $0.status != "archived" }
        return try modelContext.fetch(descriptor)
    }

    func countAlivePlants() throws -> Int {
        var descriptor = FetchDescriptor<Plant>()
        descriptor.predicate = #Predicate { $0.status != "archived" }
        return try modelContext.fetchCount(descriptor)
    }
}
