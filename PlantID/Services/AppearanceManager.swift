import SwiftUI
import Observation

@Observable
final class AppearanceManager {
    private static let storageKey = "app_appearance"
    static let allowedModes: [String] = ["system", "light", "dark"]

    private var _appearanceMode: String = {
        let stored = UserDefaults.standard.string(forKey: "app_appearance") ?? "system"
        return ["system", "light", "dark"].contains(stored) ? stored : "system"
    }()

    var appearanceMode: String {
        get { _appearanceMode }
        set {
            guard Self.allowedModes.contains(newValue) else { return }
            _appearanceMode = newValue
            UserDefaults.standard.set(newValue, forKey: Self.storageKey)
        }
    }

    var colorScheme: ColorScheme? {
        switch _appearanceMode {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }
}
