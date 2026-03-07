import SwiftData
import Observation
import Foundation

@Observable
final class EditPlantViewModel {
    var iconName: String = "monstera"
    var name: String = ""
    var species: String = ""
    var acquiredDate: Date = Date()
    var wateringIntervalDays: Int = 7
    var notes: String = ""
    var nfcTagId: String = ""
    var isLoading: Bool = false
    var nameError: String? = nil

    private var plant: Plant? = nil
    private let plantRepo: PlantRepository

    init(plantRepo: PlantRepository) {
        self.plantRepo = plantRepo
    }

    func loadPlant(id: UUID) {
        guard let p = try? plantRepo.getPlantById(id) else { return }
        plant = p
        iconName = p.iconName
        name = p.name
        species = p.species
        acquiredDate = p.acquiredDate
        wateringIntervalDays = p.wateringIntervalDays
        notes = p.notes
        nfcTagId = p.nfcTagId
    }

    func savePlant() -> Bool {
        guard let plant else { return false }
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty { nameError = "Plant name is required"; return false }
        nameError = nil
        plant.iconName = iconName
        plant.name = trimmed
        plant.species = species.trimmingCharacters(in: .whitespaces)
        plant.acquiredDate = acquiredDate
        plant.wateringIntervalDays = wateringIntervalDays
        plant.notes = notes.trimmingCharacters(in: .whitespaces)
        do {
            try plantRepo.update()
            return true
        } catch {
            return false
        }
    }

    func archivePlant() -> Bool {
        guard let plant else { return false }
        plant.status = "archived"
        plant.archivedAt = Date()
        return (try? plantRepo.update()) != nil
    }
}
