import SwiftData
import Foundation

enum SeedDataService {
    private static let seededKey = "sample_data_seeded"

    @MainActor static func seedIfNeeded(
        plantRepository: PlantRepository
    ) {
        guard !UserDefaults.standard.bool(forKey: seededKey) else { return }
        do {
            let samples: [Plant] = [
                Plant(name: "Pothos", species: "Epipremnum aureum",
                      wateringIntervalDays: 5, notes: "Tolerates low light. Water when soil is dry.", iconName: "monstera"),
                Plant(name: "Cactus", species: "Echinocactus grusonii",
                      wateringIntervalDays: 21, notes: "Loves bright light. Very drought-tolerant.", iconName: "cactus"),
                Plant(name: "Snake Plant", species: "Sansevieria trifasciata",
                      wateringIntervalDays: 14, notes: "Tolerates low light. Avoid overwatering.", iconName: "schefflera"),
                Plant(name: "Monstera", species: "Monstera deliciosa",
                      wateringIntervalDays: 7, notes: "Loves warmth and humidity. Keep soil moist.", iconName: "monstera"),
            ]
            for plant in samples {
                try plantRepository.insert(plant)
            }
            UserDefaults.standard.set(true, forKey: seededKey)
        } catch {
            // Non-fatal: sample data seeding failure
        }
    }
}
