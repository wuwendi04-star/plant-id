import Testing
import Foundation
@testable import PlantID

@Suite("PhotoTimelineViewModel Tests")
struct PhotoTimelineViewModelTests {
    @Test("All filter shows all photos")
    func testAllFilter() {
        let plantRepo = MockPlantRepository()
        let photoRepo = MockPhotoRepository()
        let logRepo = MockWateringLogRepository()

        let plant = Plant(name: "Monstera")
        plantRepo.plants = [plant]

        let p1 = Photo(plant: plant, filePath: "/a.jpg", takenAt: Date())
        let p2 = Photo(plant: plant, filePath: "/b.jpg", takenAt: Date().addingTimeInterval(-100))
        photoRepo.photos = [p1, p2]

        let log = WateringLog(plant: plant, photoPath: "/a.jpg")
        logRepo.logs = [log]

        let vm = PhotoTimelineViewModel(plantRepo: plantRepo, photoRepo: photoRepo, wateringLogRepo: logRepo)
        vm.loadData(plantId: plant.id)

        vm.selectedFilter = .all
        #expect(vm.filteredPhotos.count == 2)
    }

    @Test("Watering filter shows only watering photos")
    func testWateringFilter() {
        let plantRepo = MockPlantRepository()
        let photoRepo = MockPhotoRepository()
        let logRepo = MockWateringLogRepository()

        let plant = Plant(name: "Fern")
        plantRepo.plants = [plant]

        let watering = Photo(plant: plant, filePath: "/watering.jpg")
        let manual = Photo(plant: plant, filePath: "/manual.jpg")
        photoRepo.photos = [watering, manual]

        let log = WateringLog(plant: plant, photoPath: "/watering.jpg")
        logRepo.logs = [log]

        let vm = PhotoTimelineViewModel(plantRepo: plantRepo, photoRepo: photoRepo, wateringLogRepo: logRepo)
        vm.loadData(plantId: plant.id)

        vm.selectedFilter = .watering
        #expect(vm.filteredPhotos.count == 1)
        #expect(vm.filteredPhotos[0].filePath == "/watering.jpg")
    }

    @Test("Manual filter shows only non-watering photos")
    func testManualFilter() {
        let plantRepo = MockPlantRepository()
        let photoRepo = MockPhotoRepository()
        let logRepo = MockWateringLogRepository()

        let plant = Plant(name: "Rose")
        plantRepo.plants = [plant]

        let watering = Photo(plant: plant, filePath: "/watering.jpg")
        let manual = Photo(plant: plant, filePath: "/manual.jpg")
        photoRepo.photos = [watering, manual]

        let log = WateringLog(plant: plant, photoPath: "/watering.jpg")
        logRepo.logs = [log]

        let vm = PhotoTimelineViewModel(plantRepo: plantRepo, photoRepo: photoRepo, wateringLogRepo: logRepo)
        vm.loadData(plantId: plant.id)

        vm.selectedFilter = .manual
        #expect(vm.filteredPhotos.count == 1)
        #expect(vm.filteredPhotos[0].filePath == "/manual.jpg")
    }

    @Test("Grouped photos organizes by month")
    func testMonthGrouping() {
        let plantRepo = MockPlantRepository()
        let photoRepo = MockPhotoRepository()
        let logRepo = MockWateringLogRepository()

        let plant = Plant(name: "Palm")
        plantRepo.plants = [plant]

        var cal = Calendar.current
        let thisMonth = Date()
        let lastMonth = cal.date(byAdding: .month, value: -1, to: thisMonth)!

        let p1 = Photo(plant: plant, filePath: "/1.jpg", takenAt: thisMonth)
        let p2 = Photo(plant: plant, filePath: "/2.jpg", takenAt: thisMonth.addingTimeInterval(-3600))
        let p3 = Photo(plant: plant, filePath: "/3.jpg", takenAt: lastMonth)
        photoRepo.photos = [p1, p2, p3]

        let vm = PhotoTimelineViewModel(plantRepo: plantRepo, photoRepo: photoRepo, wateringLogRepo: logRepo)
        vm.loadData(plantId: plant.id)

        #expect(vm.groupedPhotos.count == 2)
        #expect(vm.groupedPhotos[0].photos.count == 2)  // this month
        #expect(vm.groupedPhotos[1].photos.count == 1)  // last month
    }

    @Test("Stats loaded correctly")
    func testStats() {
        let plantRepo = MockPlantRepository()
        let photoRepo = MockPhotoRepository()
        let logRepo = MockWateringLogRepository()

        let plant = Plant(name: "Cactus", acquiredDate: Date().addingTimeInterval(-30 * 86400))
        plantRepo.plants = [plant]
        logRepo.logs = [WateringLog(plant: plant), WateringLog(plant: plant), WateringLog(plant: plant)]
        photoRepo.photos = [Photo(plant: plant, filePath: "/x.jpg")]

        let vm = PhotoTimelineViewModel(plantRepo: plantRepo, photoRepo: photoRepo, wateringLogRepo: logRepo)
        vm.loadData(plantId: plant.id)

        #expect(vm.totalWaterings == 3)
        #expect(vm.daysKept >= 29)
    }
}
