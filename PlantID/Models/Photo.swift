import SwiftData
import Foundation

@Model
final class Photo {
    var id: UUID
    var plant: Plant?
    var filePath: String
    var takenAt: Date
    var note: String

    init(
        id: UUID = UUID(),
        plant: Plant? = nil,
        filePath: String,
        takenAt: Date = Date(),
        note: String = ""
    ) {
        self.id = id
        self.plant = plant
        self.filePath = filePath
        self.takenAt = takenAt
        self.note = note
    }
}
