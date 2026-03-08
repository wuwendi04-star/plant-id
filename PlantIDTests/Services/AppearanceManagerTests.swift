import Testing
import SwiftUI
@testable import PlantID

@Suite("AppearanceManager Tests")
@MainActor
struct AppearanceManagerTests {
    init() {
        UserDefaults.standard.removeObject(forKey: "app_appearance")
    }

    @Test("Default appearance is system when no stored value")
    func testDefaultAppearanceIsSystem() {
        let manager = AppearanceManager()
        #expect(manager.appearanceMode == "system")
    }

    @Test("System mode returns nil colorScheme")
    func testSystemReturnsNilColorScheme() {
        let manager = AppearanceManager()
        manager.appearanceMode = "system"
        #expect(manager.colorScheme == nil)
    }

    @Test("Light mode returns light colorScheme")
    func testLightMode() {
        let manager = AppearanceManager()
        manager.appearanceMode = "light"
        #expect(manager.colorScheme == .light)
    }

    @Test("Dark mode returns dark colorScheme")
    func testDarkMode() {
        let manager = AppearanceManager()
        manager.appearanceMode = "dark"
        #expect(manager.colorScheme == .dark)
    }

    @Test("Invalid mode is rejected")
    func testInvalidModeRejected() {
        let manager = AppearanceManager()
        manager.appearanceMode = "invalid"
        #expect(manager.appearanceMode == "system")
        #expect(manager.colorScheme == nil)
    }

    @Test("appearanceMode persists to UserDefaults")
    func testPersistence() {
        let manager = AppearanceManager()
        manager.appearanceMode = "dark"
        #expect(UserDefaults.standard.string(forKey: "app_appearance") == "dark")
    }
}
