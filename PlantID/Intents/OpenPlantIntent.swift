import AppIntents
import UIKit

/// An App Intent that opens PlantID to a specific plant's detail screen.
///
/// Users add this via Shortcuts → Automations → NFC → Add Action → "Open Plant in PlantID".
/// iOS 17 discovers this intent at build time — no manual registration is needed.
struct OpenPlantIntent: AppIntent {
    static let title: LocalizedStringResource = "Open Plant in PlantID"
    static let description = IntentDescription(
        "Opens a specific plant's detail page in PlantID.",
        categoryName: "Plant Management"
    )
    /// Required so that iOS opens the main app before running perform().
    /// Without this, the intent runs in the Shortcuts extension process and
    /// UIApplication.shared.open() is silently ignored.
    static let openAppWhenRun: Bool = true

    /// The plant to open. Shortcuts shows a picker populated by `PlantEntityQuery`.
    @Parameter(title: "Plant")
    var plant: PlantEntity

    /// Opens the app via URL scheme. `perform()` is nonisolated to satisfy the
    /// `AppIntent` protocol requirement; `UIApplication.shared.open` is called
    /// on the main actor via `MainActor.run`.
    func perform() async throws -> some IntentResult {
        let urlString = "plantid://plant/\(plant.id.uuidString)"
        guard let url = URL(string: urlString) else {
            throw OpenPlantIntentError.invalidURL
        }
        await MainActor.run {
            UIApplication.shared.open(url)
        }
        return .result()
    }
}

// MARK: - Error

enum OpenPlantIntentError: LocalizedError {
    case invalidURL

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Could not construct a URL for this plant."
        }
    }
}
