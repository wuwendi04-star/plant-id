import SwiftData
import Observation
import Foundation

@Observable
final class CreatePlantViewModel {
    var iconName: String = "monstera"
    var name: String = ""
    var species: String = ""
    var acquiredDate: Date = Date()
    var wateringIntervalDays: Int = 7
    var notes: String = ""
    var nfcTagId: String = ""

    var nameError: String? = nil
    var speciesError: String? = nil
    var isLoading: Bool = false

    private let plantRepo: PlantRepository

    init(plantRepo: PlantRepository) {
        self.plantRepo = plantRepo
    }

    func prefillNfcTag(_ tagId: String) {
        nfcTagId = tagId
    }

    func validate() -> Bool {
        var valid = true
        nameError = nil
        speciesError = nil
        if name.trimmingCharacters(in: .whitespaces).isEmpty {
            nameError = "Plant name is required"
            valid = false
        }
        if species.trimmingCharacters(in: .whitespaces).isEmpty {
            speciesError = "Species is required"
            valid = false
        }
        return valid
    }

    func createPlant() -> Bool {
        guard validate() else { return false }
        isLoading = true
        let plant = Plant(
            name: name.trimmingCharacters(in: .whitespaces),
            species: species.trimmingCharacters(in: .whitespaces),
            acquiredDate: acquiredDate,
            wateringIntervalDays: wateringIntervalDays,
            notes: notes.trimmingCharacters(in: .whitespaces),
            iconName: iconName,
            nfcTagId: nfcTagId
        )
        do {
            try plantRepo.insert(plant)
            isLoading = false
            return true
        } catch {
            isLoading = false
            return false
        }
    }
}
