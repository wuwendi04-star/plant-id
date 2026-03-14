import Foundation
import Observation

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
}
