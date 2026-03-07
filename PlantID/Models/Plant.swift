import SwiftData
import Foundation

@Model
final class Plant {
    var id: UUID
    var name: String
    var species: String
    var acquiredDate: Date
    var wateringIntervalDays: Int
    var notes: String
    var iconName: String
    var status: String
    var nfcTagId: String
    var createdAt: Date
    var archivedAt: Date?

    @Relationship(deleteRule: .cascade, inverse: \WateringLog.plant)
    var wateringLogs: [WateringLog] = []

    @Relationship(deleteRule: .cascade, inverse: \Photo.plant)
    var photos: [Photo] = []

    init(
        id: UUID = UUID(),
        name: String,
        species: String = "",
        acquiredDate: Date = Date(),
        wateringIntervalDays: Int = 7,
        notes: String = "",
        iconName: String = "monstera",
        status: String = "alive",
        nfcTagId: String = "",
        createdAt: Date = Date(),
        archivedAt: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.species = species
        self.acquiredDate = acquiredDate
        self.wateringIntervalDays = wateringIntervalDays
        self.notes = notes
        self.iconName = iconName
        self.status = status
        self.nfcTagId = nfcTagId
        self.createdAt = createdAt
        self.archivedAt = archivedAt
    }
}

extension Plant {
    static let iconNames: [String] = [
        "monstera", "cactus", "money-tree", "succulent",
        "bird-of-paradise", "spider-plant", "hoya", "orchid", "schefflera"
    ]

    var isAlive: Bool { status != "archived" }
    var isArchived: Bool { status == "archived" }
}
