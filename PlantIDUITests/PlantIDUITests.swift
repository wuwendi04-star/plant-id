import XCTest

final class PlantIDUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        // Force English so localized accessibility labels match test expectations
        app.launchArguments = ["--uitesting", "-app_language", "en"]
        app.launch()
    }

    // MARK: - Create Plant Flow

    func testCreatePlantFlow() throws {
        createPlant(name: "Test Monstera", species: "Monstera deliciosa")

        // Verify plant appears in home
        let plantCard = app.staticTexts["Test Monstera"]
        XCTAssertTrue(plantCard.waitForExistence(timeout: 5))
    }

    // MARK: - Water Plant Flow

    func testWaterPlantFlow() throws {
        // Navigate to care tab
        let careTab = app.buttons["Care"]
        XCTAssertTrue(careTab.waitForExistence(timeout: 5))
        careTab.tap()

        // If any plant is listed, water it
        let waterButton = app.buttons.matching(identifier: "Water").firstMatch
        if waterButton.waitForExistence(timeout: 3) {
            waterButton.tap()

            // Confirm water only
            let waterOnlyButton = app.buttons["Water Only"]
            XCTAssertTrue(waterOnlyButton.waitForExistence(timeout: 3))
            waterOnlyButton.tap()

            // Dismiss success dialog
            let doneButton = app.buttons["Done"]
            XCTAssertTrue(doneButton.waitForExistence(timeout: 3))
            doneButton.tap()
        }
    }

    // MARK: - Navigation Flow

    func testTabNavigation() throws {
        // Home tab
        let homeTab = app.buttons["Home"]
        XCTAssertTrue(homeTab.waitForExistence(timeout: 5))
        homeTab.tap()
        XCTAssertTrue(app.staticTexts["My Plants"].waitForExistence(timeout: 3))

        // Care tab
        let careTab = app.buttons["Care"]
        careTab.tap()
        XCTAssertTrue(app.staticTexts["Care"].waitForExistence(timeout: 3))

        // Profile tab
        let profileTab = app.buttons["Profile"]
        profileTab.tap()
        XCTAssertTrue(app.staticTexts["Profile"].waitForExistence(timeout: 3))
    }

    // MARK: - Archive Plant Flow

    func testArchivePlantFlow() throws {
        createPlant(name: "Archive Me", species: "Test species")

        // Open plant detail
        let plantCard = app.staticTexts["Archive Me"]
        XCTAssertTrue(plantCard.waitForExistence(timeout: 5))
        plantCard.tap()

        // Tap edit
        let editButton = app.buttons["Edit"]
        XCTAssertTrue(editButton.waitForExistence(timeout: 3))
        editButton.tap()

        // Archive
        let archiveButton = app.buttons["Archive This Plant"]
        XCTAssertTrue(archiveButton.waitForExistence(timeout: 3))
        archiveButton.tap()

        // Confirm archive
        let confirmButton = app.buttons["Archive"]
        XCTAssertTrue(confirmButton.waitForExistence(timeout: 3))
        confirmButton.tap()
    }

    // MARK: - Helpers

    private func createPlant(name: String, species: String) {
        let addButton = app.buttons["Add Plant"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 5))
        addButton.tap()

        // Fill in plant name
        let nameField = app.textFields["Plant name"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 3))
        nameField.tap()
        nameField.typeText(name)

        // Fill in species
        let speciesField = app.textFields["Species"]
        XCTAssertTrue(speciesField.waitForExistence(timeout: 3))
        speciesField.tap()
        speciesField.typeText(species)

        // Save
        let saveButton = app.buttons["Create Plant"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 3))
        saveButton.tap()
    }
}
