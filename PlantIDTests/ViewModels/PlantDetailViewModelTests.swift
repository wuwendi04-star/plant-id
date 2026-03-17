import Testing
import Foundation
@testable import PlantID

@Suite("PlantDetailViewModel Tests")
struct PlantDetailViewModelTests {
    private func makeVM(plant: Plant, logRepo: MockWateringLogRepository = MockWateringLogRepository()) -> PlantDetailViewModel {
        let plantRepo = MockPlantRepository()
        plantRepo.plants = [plant]
        return PlantDetailViewModel(
            plantRepo: plantRepo,
            wateringLogRepo: logRepo,
            photoRepo: MockPhotoRepository()
        )
    }

    @Test("Load plant by ID")
    func testLoadPlant() {
        let plant = Plant(name: "Monstera")
        let vm = makeVM(plant: plant)
        vm.loadPlant(id: plant.id)
        #expect(vm.plant?.name == "Monstera")
    }

    @Test("Add watering inserts log and shows success")
    func testAddWatering() {
        let plant = Plant(name: "Fern")
        let logRepo = MockWateringLogRepository()
        let plantRepo = MockPlantRepository()
        plantRepo.plants = [plant]
        let vm = PlantDetailViewModel(
            plantRepo: plantRepo,
            wateringLogRepo: logRepo,
            photoRepo: MockPhotoRepository()
        )
        vm.plant = plant
        vm.addWatering()
        #expect(logRepo.logs.count == 1)
        #expect(vm.showWateringSuccess)
    }

    @Test("Archive plant updates status to archived")
    func testArchive() {
        let plantRepo = MockPlantRepository()
        let plant = Plant(name: "Old Plant")
        plantRepo.plants = [plant]

        let vm = PlantDetailViewModel(
            plantRepo: plantRepo,
            wateringLogRepo: MockWateringLogRepository(),
            photoRepo: MockPhotoRepository()
        )
        vm.plant = plant
        let result = vm.archivePlant()
        #expect(result)
        #expect(plantRepo.plants[0].status == "archived")
        #expect(plantRepo.plants[0].archivedAt != nil)
    }

    @Test("Delete plant removes from repo")
    func testDelete() {
        let plantRepo = MockPlantRepository()
        let plant = Plant(name: "Delete Me")
        plantRepo.plants = [plant]

        let vm = PlantDetailViewModel(
            plantRepo: plantRepo,
            wateringLogRepo: MockWateringLogRepository(),
            photoRepo: MockPhotoRepository()
        )
        vm.plant = plant
        let result = vm.deletePlant()
        #expect(result)
        #expect(plantRepo.plants.isEmpty)
    }

    @Test("Dismiss watering success clears flag")
    func testDismissSuccess() {
        let plant = Plant(name: "P")
        let vm = makeVM(plant: plant)
        vm.showWateringSuccess = true
        vm.dismissWateringSuccess()
        #expect(!vm.showWateringSuccess)
    }

    @Test("Unknown plant ID returns nil plant")
    func testUnknownId() {
        let vm = PlantDetailViewModel(
            plantRepo: MockPlantRepository(),
            wateringLogRepo: MockWateringLogRepository(),
            photoRepo: MockPhotoRepository()
        )
        vm.loadPlant(id: UUID())
        #expect(vm.plant == nil)
    }
}
