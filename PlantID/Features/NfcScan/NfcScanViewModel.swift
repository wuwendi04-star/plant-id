import SwiftData
import Observation
import Foundation

enum NfcNavEvent: Equatable {
    case none
    case goToDetail(UUID)
    case goToCreate(String)
    case tagOrphaned(String)
}

@MainActor
@Observable
final class NfcScanViewModel {
    var navEvent: NfcNavEvent = .none
    var allowGoToCreate: Bool = false
    var showNfcSuccessDialog: Bool = false
    var lastTagId: String? = nil
    private var boundTagIds: Set<String> = []

    private let plantRepo: PlantRepository

    init(plantRepo: PlantRepository) {
        self.plantRepo = plantRepo
    }

    func loadBoundTags() {
        let ids = (try? plantRepo.getAllNfcTagIds()) ?? []
        boundTagIds = Set(ids)
    }

    func processTag(_ tagId: String) {
        lastTagId = tagId
        if let plant = try? plantRepo.getPlantByNfcTag(tagId) {
            boundTagIds.insert(tagId)
            navEvent = .goToDetail(plant.id)
        } else if boundTagIds.contains(tagId) {
            boundTagIds.remove(tagId)
            navEvent = .tagOrphaned(tagId)
        } else if allowGoToCreate {
            navEvent = .goToCreate(tagId)
        }
    }

    func setCreateMode(_ enabled: Bool) { allowGoToCreate = enabled }
    func consumeNavEvent() { navEvent = .none }
    func showSuccess() { showNfcSuccessDialog = true }
    func hideSuccess() { showNfcSuccessDialog = false }
    func navigateToPlant(_ id: UUID) { navEvent = .goToDetail(id) }
}
