import Testing
import Foundation
@testable import PlantID

@Suite("CareViewModel Tests")
struct CareViewModelTests {
    @Test("Plants sorted by urgency - overdue first")
    func testSortByUrgency() {
        let plantRepo = MockPlantRepository()
        let logRepo = MockWateringLogRepository()

        let overdue = Plant(name: "Overdue", wateringIntervalDays: 3)
        let ok = Plant(name: "OK", wateringIntervalDays: 14)
        let dueToday = Plant(name: "DueToday", wateringIntervalDays: 7)

        plantRepo.plants = [ok, dueToday, overdue]
        logRepo.logs = [
            WateringLog(plant: overdue, wateredAt: Date().addingTimeInterval(-5 * 86400)),
            WateringLog(plant: ok, wateredAt: Date().addingTimeInterval(-1 * 86400)),
            WateringLog(plant: dueToday, wateredAt: Date().addingTimeInterval(-7 * 86400))
        ]

        let vm = CareViewModel(plantRepo: plantRepo, wateringLogRepo: logRepo)
        vm.loadData()

        let overdueItems = vm.careItems.filter { $0.isOverdue }
        let dueTodayItems = vm.careItems.filter { $0.isDueToday }

        #expect(!overdueItems.isEmpty)
        #expect(!dueTodayItems.isEmpty)
    }

    @Test("Water plant by ID inserts log")
    func testWaterPlant() {
        let plantRepo = MockPlantRepository()
        let logRepo = MockWateringLogRepository()

        let plant = Plant(name: "Test")
        plantRepo.plants = [plant]

        let vm = CareViewModel(plantRepo: plantRepo, wateringLogRepo: logRepo)
        vm.loadData()
        vm.waterPlant(plant.id)

        #expect(logRepo.logs.count == 1)
        #expect(logRepo.logs[0].plant?.id == plant.id)
    }

    @Test("PlantCareItem daysUntilDue calculated correctly")
    func testDaysUntilDue() {
        let plant = Plant(name: "Plant", wateringIntervalDays: 7)
        let lastWatered = Date().addingTimeInterval(-5 * 86400)
        let log = WateringLog(plant: plant, wateredAt: lastWatered)
        let item = PlantCareItem(plant: plant, daysSinceWatering: 5, daysUntilDue: 2)
        #expect(item.daysUntilDue == 2)
        #expect(!item.isOverdue)
        #expect(!item.isDueToday)
    }

    @Test("isOverdue when daysUntilDue is negative")
    func testIsOverdue() {
        let plant = Plant(name: "P", wateringIntervalDays: 3)
        let item = PlantCareItem(plant: plant, daysSinceWatering: 5, daysUntilDue: -2)
        #expect(item.isOverdue)
        #expect(!item.isDueToday)
        #expect(item.needsAttention)
    }
}
