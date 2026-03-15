import Foundation
import Observation
import SwiftUI

@Observable
final class LanguageManager {
    private static let storageKey = "app_language"
    static let allowedCodes: [String] = ["en", "zh-Hans"]

    private var _languageCode: String = {
        let stored = UserDefaults.standard.string(forKey: "app_language") ?? "en"
        return ["en", "zh-Hans"].contains(stored) ? stored : "en"
    }()

    var languageCode: String {
        get { _languageCode }
        set {
            guard Self.allowedCodes.contains(newValue) else { return }
            _languageCode = newValue
            UserDefaults.standard.set(newValue, forKey: Self.storageKey)
        }
    }

    var locale: Locale {
        Locale(identifier: _languageCode)
    }

    /// Returns a Bundle pointing to the correct .lproj for the selected language.
    /// Views should use Text("key", bundle: languageManager.bundle) for runtime switching.
    var bundle: Bundle {
        Bundle.main.path(forResource: _languageCode, ofType: "lproj")
            .flatMap { Bundle(path: $0) } ?? .main
    }
}

// MARK: - Environment Key

struct LocalizedBundleKey: EnvironmentKey {
    static let defaultValue: Bundle = .main
}

extension EnvironmentValues {
    var localizedBundle: Bundle {
        get { self[LocalizedBundleKey.self] }
        set { self[LocalizedBundleKey.self] = newValue }
    }
}
