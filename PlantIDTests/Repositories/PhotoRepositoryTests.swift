import Testing
import SwiftData
import Foundation
@testable import PlantID

@Suite("PhotoRepository Tests")
@MainActor
struct PhotoRepositoryTests {
    private func makeRepos() throws -> (SwiftDataPhotoRepository, SwiftDataPlantRepository, ModelContainer) {
        let schema = Schema([Plant.self, WateringLog.self, Photo.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: config)
        let ctx = ModelContext(container)
        return (
            SwiftDataPhotoRepository(modelContext: ctx),
            SwiftDataPlantRepository(modelContext: ctx),
            container
        )
    }

    @Test("Insert and fetch photos by plant")
    func testInsertAndFetch() throws {
        let (photoRepo, plantRepo, _) = try makeRepos()
        let plant = Plant(name: "Monstera")
        try plantRepo.insert(plant)

        let photo = Photo(plant: plant, filePath: "/tmp/photo.jpg", takenAt: Date())
        try photoRepo.insert(photo)

        let photos = try photoRepo.getPhotosByPlant(plant.id)
        #expect(photos.count == 1)
        #expect(photos[0].filePath == "/tmp/photo.jpg")
    }

    @Test("Get latest photo")
    func testGetLatestPhoto() throws {
        let (photoRepo, plantRepo, _) = try makeRepos()
        let plant = Plant(name: "Fern")
        try plantRepo.insert(plant)

        let old = Photo(plant: plant, filePath: "/old.jpg", takenAt: Date().addingTimeInterval(-3600))
        let latest = Photo(plant: plant, filePath: "/new.jpg", takenAt: Date())
        try photoRepo.insert(old)
        try photoRepo.insert(latest)

        let result = try photoRepo.getLatestPhoto(plantId: plant.id)
        #expect(result?.filePath == "/new.jpg")
    }

    @Test("Delete photo")
    func testDelete() throws {
        let (photoRepo, plantRepo, _) = try makeRepos()
        let plant = Plant(name: "Rose")
        try plantRepo.insert(plant)
        let photo = Photo(plant: plant, filePath: "/x.jpg")
        try photoRepo.insert(photo)
        try photoRepo.delete(photo)
        let photos = try photoRepo.getPhotosByPlant(plant.id)
        #expect(photos.isEmpty)
    }

    @Test("Count all photos")
    func testCountAll() throws {
        let (photoRepo, plantRepo, _) = try makeRepos()
        let p = Plant(name: "Palm")
        try plantRepo.insert(p)
        try photoRepo.insert(Photo(plant: p, filePath: "/a.jpg"))
        try photoRepo.insert(Photo(plant: p, filePath: "/b.jpg"))
        let count = try photoRepo.countAll()
        #expect(count == 2)
    }
}
