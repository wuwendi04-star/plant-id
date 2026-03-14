import Foundation
@testable import PlantID

// MARK: - MockPlantRepository

@MainActor
final class MockPlantRepository: PlantRepository {
    var plants: [Plant] = []
    var shouldThrow = false

    func insert(_ plant: Plant) throws {
        if shouldThrow { throw MockError.generic }
        plants.append(plant)
    }

    func update() throws {
        if shouldThrow { throw MockError.generic }
    }

    func delete(_ plant: Plant) throws {
        plants.removeAll { $0.id == plant.id }
    }

    func getAlivePlants() throws -> [Plant] {
        plants.filter { $0.status != "archived" }
    }

    func getArchivedPlants() throws -> [Plant] {
        plants.filter { $0.status == "archived" }
    }

    func getPlantById(_ id: UUID) throws -> Plant? {
        plants.first { $0.id == id }
    }

    func getPlantByNfcTag(_ tagId: String) throws -> Plant? {
        plants.first { $0.nfcTagId == tagId }
    }

    func getAllNfcTagIds() throws -> [String] {
        plants.compactMap { $0.nfcTagId.isEmpty ? nil : $0.nfcTagId }
    }

    func getAllAlivePlantsSnapshot() throws -> [Plant] {
        plants.filter { $0.status != "archived" }
    }

    func countAlivePlants() throws -> Int {
        plants.filter { $0.status != "archived" }.count
    }
}

// MARK: - MockWateringLogRepository

@MainActor
final class MockWateringLogRepository: WateringLogRepository {
    var logs: [WateringLog] = []
    var shouldThrow = false

    func insert(_ log: WateringLog) throws {
        if shouldThrow { throw MockError.generic }
        logs.append(log)
    }

    func delete(_ log: WateringLog) throws {
        logs.removeAll { $0.id == log.id }
    }

    func getLogsByPlant(_ plantId: UUID) throws -> [WateringLog] {
        logs.filter { $0.plant?.id == plantId }
    }

    func getLastWatering(plantId: UUID) throws -> WateringLog? {
        logs
            .filter { $0.plant?.id == plantId }
            .sorted { $0.wateredAt > $1.wateredAt }
            .first
    }

    func countByPlant(_ plantId: UUID) throws -> Int {
        logs.filter { $0.plant?.id == plantId }.count
    }

    func countAll() throws -> Int {
        logs.count
    }
}

// MARK: - MockPhotoRepository

@MainActor
final class MockPhotoRepository: PhotoRepository {
    var photos: [Photo] = []
    var shouldThrow = false

    func insert(_ photo: Photo) throws {
        if shouldThrow { throw MockError.generic }
        photos.append(photo)
    }

    func delete(_ photo: Photo) throws {
        photos.removeAll { $0.id == photo.id }
    }

    func getPhotosByPlant(_ plantId: UUID) throws -> [Photo] {
        photos.filter { $0.plant?.id == plantId }
    }

    func getLatestPhoto(plantId: UUID) throws -> Photo? {
        photos
            .filter { $0.plant?.id == plantId }
            .sorted { $0.takenAt > $1.takenAt }
            .first
    }

    func countAll() throws -> Int {
        photos.count
    }
}

// MARK: - MockError

enum MockError: Error {
    case generic
}
