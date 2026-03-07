import SwiftData
import Foundation

final class SwiftDataPhotoRepository: PhotoRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func insert(_ photo: Photo) throws {
        modelContext.insert(photo)
        try modelContext.save()
    }

    func delete(_ photo: Photo) throws {
        modelContext.delete(photo)
        try modelContext.save()
    }

    func getPhotosByPlant(_ plantId: UUID) throws -> [Photo] {
        var descriptor = FetchDescriptor<Photo>(
            sortBy: [SortDescriptor(\.takenAt, order: .reverse)]
        )
        descriptor.predicate = #Predicate { $0.plant?.id == plantId }
        return try modelContext.fetch(descriptor)
    }

    func getLatestPhoto(plantId: UUID) throws -> Photo? {
        var descriptor = FetchDescriptor<Photo>(
            sortBy: [SortDescriptor(\.takenAt, order: .reverse)]
        )
        descriptor.predicate = #Predicate { $0.plant?.id == plantId }
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }

    func countAll() throws -> Int {
        try modelContext.fetchCount(FetchDescriptor<Photo>())
    }
}
