import SwiftData
import Foundation

@Model
final class WateringLog {
    var id: UUID
    var plant: Plant?
    var wateredAt: Date
    var photoPath: String

    init(
        id: UUID = UUID(),
        plant: Plant? = nil,
        wateredAt: Date = Date(),
        photoPath: String = ""
    ) {
        self.id = id
        self.plant = plant
        self.wateredAt = wateredAt
        self.photoPath = photoPath
    }
}
