import Testing
import Foundation
@testable import PlantID

@Suite("LanguageManager Tests", .serialized)
@MainActor
struct LanguageManagerTests {
    init() {
        UserDefaults.standard.removeObject(forKey: "app_language")
    }

    @Test("Default language is English when no stored value")
    func testDefaultLanguageIsEnglish() {
        let manager = LanguageManager()
        #expect(manager.languageCode == "en")
    }

    @Test("Locale reflects languageCode for English")
    func testEnglishLocale() {
        let manager = LanguageManager()
        manager.languageCode = "en"
        #expect(manager.locale.identifier == "en")
    }

    @Test("Locale reflects languageCode for Chinese")
    func testChineseLocale() {
        let manager = LanguageManager()
        manager.languageCode = "zh-Hans"
        #expect(manager.locale.identifier == "zh-Hans")
    }

    @Test("Switching language updates locale")
    func testSwitchingLanguageUpdatesLocale() {
        let manager = LanguageManager()
        manager.languageCode = "zh-Hans"
        #expect(manager.locale.identifier == "zh-Hans")
        manager.languageCode = "en"
        #expect(manager.locale.identifier == "en")
    }

    @Test("Invalid language code is rejected")
    func testInvalidLanguageCodeRejected() {
        let manager = LanguageManager()
        manager.languageCode = "fr"
        #expect(manager.languageCode == "en")
    }

    @Test("languageCode persists to UserDefaults")
    func testPersistence() {
        let manager = LanguageManager()
        manager.languageCode = "zh-Hans"
        #expect(UserDefaults.standard.string(forKey: "app_language") == "zh-Hans")
    }
}
