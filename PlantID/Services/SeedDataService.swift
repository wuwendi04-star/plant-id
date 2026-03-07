import SwiftData
import Foundation

enum SeedDataService {
    private static let seededKey = "sample_data_seeded"

    static func seedIfNeeded(
        plantRepository: PlantRepository
    ) {
        guard !UserDefaults.standard.bool(forKey: seededKey) else { return }
        do {
            let samples: [Plant] = [
                Plant(name: "Pothos", species: "Epipremnum aureum",
                      wateringIntervalDays: 5, iconName: "monstera",
                      notes: "Tolerates low light. Water when soil is dry."),
                Plant(name: "Cactus", species: "Echinocactus grusonii",
                      wateringIntervalDays: 21, iconName: "cactus",
                      notes: "Loves bright light. Very drought-tolerant."),
                Plant(name: "Snake Plant", species: "Sansevieria trifasciata",
                      wateringIntervalDays: 14, iconName: "schefflera",
                      notes: "Tolerates low light. Avoid overwatering."),
                Plant(name: "Monstera", species: "Monstera deliciosa",
                      wateringIntervalDays: 7, iconName: "monstera",
                      notes: "Loves warmth and humidity. Keep soil moist."),
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
