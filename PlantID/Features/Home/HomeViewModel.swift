import SwiftData
import Observation
import Foundation

enum WateringUrgency {
    case ok
    case dueToday
    case overdue
}

@MainActor
@Observable
final class HomeViewModel {
    var selectedTab: Int = 0
    var alivePlants: [Plant] = []
    var archivedPlants: [Plant] = []
    var daysUntilWateringMap: [UUID: Int] = [:]

    var wateringStatusMap: [UUID: WateringUrgency] {
        daysUntilWateringMap.mapValues { days in
            if days < 0 { return .overdue }
            if days == 0 { return .dueToday }
            return .ok
        }
    }

    private let plantRepo: PlantRepository
    private let wateringLogRepo: WateringLogRepository

    init(plantRepo: PlantRepository, wateringLogRepo: WateringLogRepository) {
        self.plantRepo = plantRepo
        self.wateringLogRepo = wateringLogRepo
    }

    func loadData() {
        do {
            alivePlants = try plantRepo.getAlivePlants()
            archivedPlants = try plantRepo.getArchivedPlants()
            computeWateringStatus()
        } catch {
            // Maintain current state on error
        }
    }

    private func computeWateringStatus() {
        var map: [UUID: Int] = [:]
        for plant in alivePlants {
            let last = try? wateringLogRepo.getLastWatering(plantId: plant.id)
            let daysSince = last.map { Date().daysSince($0.wateredAt) } ?? Date().daysSince(plant.acquiredDate)

            let daysUntilWatering = plant.wateringIntervalDays - daysSince
            map[plant.id] = daysUntilWatering
        }
        daysUntilWateringMap = map
    }
}
