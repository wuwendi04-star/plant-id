import SwiftData
import Observation
import Foundation

enum WateringUrgency {
    case ok
    case dueToday
    case overdue
}

@Observable
final class HomeViewModel {
    var selectedTab: Int = 0
    var alivePlants: [Plant] = []
    var archivedPlants: [Plant] = []
    var wateringStatusMap: [UUID: WateringUrgency] = [:]

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
        var map: [UUID: WateringUrgency] = [:]
        for plant in alivePlants {
            let last = try? wateringLogRepo.getLastWatering(plantId: plant.id)
            let daysSince = last.map { Date().daysSince($0.wateredAt) } ?? -1

            let urgency: WateringUrgency
            switch daysSince {
            case ..<0:
                urgency = .ok
            case let d where d > plant.wateringIntervalDays:
                urgency = .overdue
            case let d where d == plant.wateringIntervalDays:
                urgency = .dueToday
            default:
                urgency = .ok
            }
            map[plant.id] = urgency
        }
        wateringStatusMap = map
    }
}
