import SwiftData
import Observation
import Foundation

enum PhotoFilter: String, CaseIterable {
    case all = "All"
    case watering = "Watering"
    case manual = "Manual"
}

struct PhotoGroup: Identifiable {
    let month: Date
    let photos: [Photo]
    var id: Date { month }
}

@Observable
final class PhotoTimelineViewModel {
    var allPhotos: [Photo] = []
    var wateringLogPhotoPaths: Set<String> = []
    var selectedFilter: PhotoFilter = .all
    var totalWaterings: Int = 0
    var daysKept: Int = 0

    private let plantRepo: PlantRepository
    private let photoRepo: PhotoRepository
    private let wateringLogRepo: WateringLogRepository

    init(
        plantRepo: PlantRepository,
        photoRepo: PhotoRepository,
        wateringLogRepo: WateringLogRepository
    ) {
        self.plantRepo = plantRepo
        self.photoRepo = photoRepo
        self.wateringLogRepo = wateringLogRepo
    }

    var filteredPhotos: [Photo] {
        switch selectedFilter {
        case .all: return allPhotos
        case .watering: return allPhotos.filter { wateringLogPhotoPaths.contains($0.filePath) }
        case .manual: return allPhotos.filter { !wateringLogPhotoPaths.contains($0.filePath) }
        }
    }

    var groupedPhotos: [PhotoGroup] {
        let photos = filteredPhotos
        var groups: [Date: [Photo]] = [:]
        let cal = Calendar.current
        for photo in photos {
            let monthStart = cal.date(from: cal.dateComponents([.year, .month], from: photo.takenAt)) ?? photo.takenAt
            groups[monthStart, default: []].append(photo)
        }
        return groups.map { PhotoGroup(month: $0.key, photos: $0.value.sorted { $0.takenAt > $1.takenAt }) }
            .sorted { $0.month > $1.month }
    }

    func loadData(plantId: UUID) {
        allPhotos = (try? photoRepo.getPhotosByPlant(plantId)) ?? []
        let logs = (try? wateringLogRepo.getLogsByPlant(plantId)) ?? []
        wateringLogPhotoPaths = Set(logs.compactMap { $0.photoPath.isEmpty ? nil : $0.photoPath })
        totalWaterings = logs.count
        let plant = try? plantRepo.getPlantById(plantId)
        daysKept = plant.map { Date().daysSince($0.acquiredDate) } ?? 0
    }
}
