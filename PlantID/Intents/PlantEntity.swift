import AppIntents
import Foundation

/// Represents a Plant in the Apple Shortcuts / App Intents system.
///
/// Stores `name` and `species` as value-type properties so they are accessible
/// for filtering and testing without digging into `displayRepresentation`.
/// The SwiftData `@Model` class is not `Sendable` and cannot be used directly.
struct PlantEntity: AppEntity {
    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Plant")
    static let defaultQuery = PlantEntityQuery()

    let id: UUID
    let name: String
    let species: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(name)",
            subtitle: species.isEmpty ? nil : "\(species)"
        )
    }

    init(id: UUID, name: String, species: String) {
        self.id = id
        self.name = name
        self.species = species
    }
}
