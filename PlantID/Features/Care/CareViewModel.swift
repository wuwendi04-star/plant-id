import SwiftData
import Observation
import Foundation

struct PlantCareItem: Identifiable {
    let plant: Plant
    let daysSinceWatering: Int
    let daysUntilDue: Int

    var id: UUID { plant.id }
    var isOverdue: Bool { daysUntilDue < 0 }
    var isDueToday: Bool { daysUntilDue == 0 }
    var isUpcoming: Bool { (1...2).contains(daysUntilDue) }
    var needsAttention: Bool { isOverdue || isDueToday }
}

@Observable
final class CareViewModel {
    var careItems: [PlantCareItem] = []
    var isLoading: Bool = true

    private let plantRepo: PlantRepository
    private let wateringLogRepo: WateringLogRepository

    init(plantRepo: PlantRepository, wateringLogRepo: WateringLogRepository) {
        self.plantRepo = plantRepo
        self.wateringLogRepo = wateringLogRepo
    }

    func loadData() {
        isLoading = true
        do {
            let plants = try plantRepo.getAlivePlants()
            careItems = computeItems(plants: plants)
        } catch {
            careItems = []
        }
        isLoading = false
    }

    func waterPlant(_ plantId: UUID) {
        guard let plant = careItems.first(where: { $0.id == plantId })?.plant else { return }
        let log = WateringLog(plant: plant)
        try? wateringLogRepo.insert(log)
        loadData()
    }

    private func computeItems(plants: [Plant]) -> [PlantCareItem] {
        plants.map { plant in
            let last = try? wateringLogRepo.getLastWatering(plantId: plant.id)
            let daysSince = last.map { Date().daysSince($0.wateredAt) } ?? -1
            let daysUntilDue = daysSince < 0
                ? -(plant.wateringIntervalDays + 1)
                : plant.wateringIntervalDays - daysSince
            return PlantCareItem(plant: plant, daysSinceWatering: daysSince, daysUntilDue: daysUntilDue)
        }
        .sorted { $0.daysUntilDue < $1.daysUntilDue }
    }
}
