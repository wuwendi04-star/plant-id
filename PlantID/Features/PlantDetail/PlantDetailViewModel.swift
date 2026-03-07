import SwiftData
import Observation
import Foundation

@Observable
final class PlantDetailViewModel {
    var plant: Plant? = nil
    var wateringLogs: [WateringLog] = []
    var photos: [Photo] = []
    var lastWateredDaysAgo: Int = -1
    var daysKept: Int = 0
    var isAddingWatering: Bool = false
    var showWateringSuccess: Bool = false
    var showCamera: Bool = false
    var pendingPhotoForWatering: Bool = false

    private let plantRepo: PlantRepository
    private let wateringLogRepo: WateringLogRepository
    private let photoRepo: PhotoRepository

    init(
        plantRepo: PlantRepository,
        wateringLogRepo: WateringLogRepository,
        photoRepo: PhotoRepository
    ) {
        self.plantRepo = plantRepo
        self.wateringLogRepo = wateringLogRepo
        self.photoRepo = photoRepo
    }

    func loadPlant(id: UUID) {
        plant = try? plantRepo.getPlantById(id)
        guard let plant else { return }

        daysKept = Date().daysSince(plant.acquiredDate)
        wateringLogs = (try? wateringLogRepo.getLogsByPlant(id)) ?? []
        photos = (try? photoRepo.getPhotosByPlant(id)) ?? []

        if let last = wateringLogs.first {
            lastWateredDaysAgo = Date().daysSince(last.wateredAt)
        } else {
            lastWateredDaysAgo = -1
        }
    }

    func addWatering() {
        guard let plant, !isAddingWatering else { return }
        isAddingWatering = true
        let log = WateringLog(plant: plant)
        try? wateringLogRepo.insert(log)
        isAddingWatering = false
        showWateringSuccess = true
        loadPlant(id: plant.id)
    }

    func saveWateringWithPhoto(image: UIImage) {
        guard let plant, !isAddingWatering else { return }
        isAddingWatering = true
        do {
            let path = try PhotoStorageService.save(image: image, plantId: plant.id)
            let photo = Photo(plant: plant, filePath: path)
            try photoRepo.insert(photo)
            let log = WateringLog(plant: plant, photoPath: path)
            try wateringLogRepo.insert(log)
            showWateringSuccess = true
        } catch {
            // Save watering without photo as fallback
            let log = WateringLog(plant: plant)
            try? wateringLogRepo.insert(log)
            showWateringSuccess = true
        }
        isAddingWatering = false
        loadPlant(id: plant.id)
    }

    func savePhotoOnly(image: UIImage) {
        guard let plant else { return }
        do {
            let path = try PhotoStorageService.save(image: image, plantId: plant.id)
            let photo = Photo(plant: plant, filePath: path)
            try photoRepo.insert(photo)
            loadPlant(id: plant.id)
        } catch {}
    }

    func archivePlant() -> Bool {
        guard let plant else { return false }
        plant.status = "archived"
        plant.archivedAt = Date()
        return (try? plantRepo.update()) != nil
    }

    func deletePlant() -> Bool {
        guard let plant else { return false }
        photos.forEach { PhotoStorageService.delete(filePath: $0.filePath) }
        return (try? plantRepo.delete(plant)) != nil
    }

    func dismissWateringSuccess() { showWateringSuccess = false }
}

import UIKit
