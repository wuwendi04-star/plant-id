import SwiftData
import Foundation

/// A process-lifetime singleton that vends the app's SwiftData ModelContainer
/// to App Intent query objects, which cannot access SwiftUI environment values.
///
/// `configure(_:)` is called once from `PlantIDApp.init()` before any intent
/// query fires. Using `nonisolated(unsafe)` because the property is written
/// synchronously at app startup, before the App Intents runtime can schedule
/// any query — the write always precedes any read.
final class ModelContainerProvider: Sendable {
    static let shared = ModelContainerProvider()
    private init() {}

    nonisolated(unsafe) private(set) var container: ModelContainer?

    /// Call once from `PlantIDApp.init()` to register the shared container.
    func configure(_ container: ModelContainer) {
        self.container = container
    }
}
