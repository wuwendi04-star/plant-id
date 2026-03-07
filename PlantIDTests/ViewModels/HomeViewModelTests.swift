import Testing
import Foundation
@testable import PlantID

@Suite("HomeViewModel Tests")
struct HomeViewModelTests {
    @Test("Load data populates alive plants")
    func testLoadAlivePlants() {
        let plantRepo = MockPlantRepository()
        let logRepo = MockWateringLogRepository()

        let p1 = Plant(name: "Monstera", wateringIntervalDays: 7)
        let p2 = Plant(name: "Cactus", wateringIntervalDays: 14)
        plantRepo.plants = [p1, p2]

        let watered = Date().addingTimeInterval(-3 * 86400)
        logRepo.logs = [WateringLog(plant: p1, wateredAt: watered)]

        let vm = HomeViewModel(plantRepo: plantRepo, wateringLogRepo: logRepo)
        vm.loadData()

        #expect(vm.alivePlants.count == 2)
    }

    @Test("Watering urgency computed correctly")
    func testUrgency() {
        let plantRepo = MockPlantRepository()
        let logRepo = MockWateringLogRepository()

        let overdueP = Plant(name: "Overdue", wateringIntervalDays: 3)
        let okP = Plant(name: "OK", wateringIntervalDays: 14)
        let dueTodayP = Plant(name: "DueToday", wateringIntervalDays: 7)

        plantRepo.plants = [overdueP, okP, dueTodayP]
        logRepo.logs = [
            WateringLog(plant: overdueP, wateredAt: Date().addingTimeInterval(-4 * 86400)),
            WateringLog(plant: okP, wateredAt: Date().addingTimeInterval(-2 * 86400)),
            WateringLog(plant: dueTodayP, wateredAt: Date().addingTimeInterval(-7 * 86400))
        ]

        let vm = HomeViewModel(plantRepo: plantRepo, wateringLogRepo: logRepo)
        vm.loadData()

        let overdueStatus = vm.wateringStatusMap[overdueP.id]
        let okStatus = vm.wateringStatusMap[okP.id]
        let dueTodayStatus = vm.wateringStatusMap[dueTodayP.id]

        #expect(overdueStatus == .overdue)
        #expect(okStatus == .ok)
        #expect(dueTodayStatus == .dueToday)
    }

    @Test("No logs means overdue immediately (acquired > interval days ago)")
    func testNoLogsIsOverdue() {
        let plantRepo = MockPlantRepository()
        let logRepo = MockWateringLogRepository()

        let plant = Plant(
            name: "NewPlant",
            wateringIntervalDays: 7,
            acquiredDate: Date().addingTimeInterval(-10 * 86400)
        )
        plantRepo.plants = [plant]

        let vm = HomeViewModel(plantRepo: plantRepo, wateringLogRepo: logRepo)
        vm.loadData()

        let status = vm.wateringStatusMap[plant.id]
        #expect(status == .overdue)
    }

    @Test("Archived plants loaded separately")
    func testArchivedPlants() {
        let plantRepo = MockPlantRepository()
        let alive = Plant(name: "Alive")
        let archived = Plant(name: "Archived", status: "archived")
        archived.archivedAt = Date()
        plantRepo.plants = [alive, archived]

        let vm = HomeViewModel(plantRepo: plantRepo, wateringLogRepo: MockWateringLogRepository())
        vm.loadData()

        #expect(vm.alivePlants.count == 1)
        #expect(vm.archivedPlants.count == 1)
    }
}
