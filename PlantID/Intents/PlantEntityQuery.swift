import AppIntents
import SwiftData
import Foundation

/// Resolves `PlantEntity` values for the Shortcuts editor and at intent runtime.
///
/// Methods are nonisolated (matching the `EntityQuery` protocol requirements).
/// A fresh background `ModelContext` is created per call — safe from any executor
/// without needing `@MainActor` or `mainContext`.
struct PlantEntityQuery: EntityQuery {

    /// Resolves specific plant IDs when an intent is performed.
    func entities(for identifiers: [UUID]) async throws -> [PlantEntity] {
        try fetchAlivePlants().filter { identifiers.contains($0.id) }
    }

    /// Provides a filtered list while the user types in the Shortcuts editor.
    func entities(matching string: String) async throws -> [PlantEntity] {
        let all = try fetchAlivePlants()
        guard !string.isEmpty else { return all }
        return all.filter { $0.name.localizedCaseInsensitiveContains(string) }
    }

    /// Provides the initial plant list shown before the user starts typing.
    func suggestedEntities() async throws -> [PlantEntity] {
        try fetchAlivePlants()
    }

    // MARK: - Private

    private func fetchAlivePlants() throws -> [PlantEntity] {
        guard let container = ModelContainerProvider.shared.container else { return [] }
        // Use a fresh background context — safe to create from any executor.
        let context = ModelContext(container)
        var descriptor = FetchDescriptor<Plant>(
            predicate: #Predicate { $0.status != "archived" }
        )
        descriptor.sortBy = [SortDescriptor(\.createdAt, order: .reverse)]
        let plants = try context.fetch(descriptor)
        return plants.map { PlantEntity(id: $0.id, name: $0.name, species: $0.species) }
    }
}
