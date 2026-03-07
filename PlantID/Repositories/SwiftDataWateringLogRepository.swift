import SwiftData
import Foundation

final class SwiftDataWateringLogRepository: WateringLogRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func insert(_ log: WateringLog) throws {
        modelContext.insert(log)
        try modelContext.save()
    }

    func delete(_ log: WateringLog) throws {
        modelContext.delete(log)
        try modelContext.save()
    }

    func getLogsByPlant(_ plantId: UUID) throws -> [WateringLog] {
        var descriptor = FetchDescriptor<WateringLog>(
            sortBy: [SortDescriptor(\.wateredAt, order: .reverse)]
        )
        descriptor.predicate = #Predicate { $0.plant?.id == plantId }
        return try modelContext.fetch(descriptor)
    }

    func getLastWatering(plantId: UUID) throws -> WateringLog? {
        var descriptor = FetchDescriptor<WateringLog>(
            sortBy: [SortDescriptor(\.wateredAt, order: .reverse)]
        )
        descriptor.predicate = #Predicate { $0.plant?.id == plantId }
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }

    func countByPlant(_ plantId: UUID) throws -> Int {
        var descriptor = FetchDescriptor<WateringLog>()
        descriptor.predicate = #Predicate { $0.plant?.id == plantId }
        return try modelContext.fetchCount(descriptor)
    }

    func countAll() throws -> Int {
        try modelContext.fetchCount(FetchDescriptor<WateringLog>())
    }
}
