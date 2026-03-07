import Testing
import Foundation
@testable import PlantID

@Suite("CreatePlantViewModel Tests")
struct CreatePlantViewModelTests {
    @Test("Empty name and species fails validation")
    func testEmptyNameInvalid() {
        let vm = CreatePlantViewModel(plantRepo: MockPlantRepository())
        vm.name = ""
        vm.species = ""
        #expect(!vm.validate())
        #expect(vm.nameError != nil)
    }

    @Test("Non-empty name and species passes validation")
    func testValidNameAndSpecies() {
        let vm = CreatePlantViewModel(plantRepo: MockPlantRepository())
        vm.name = "Monstera"
        vm.species = "Monstera deliciosa"
        #expect(vm.validate())
        #expect(vm.nameError == nil)
        #expect(vm.speciesError == nil)
    }

    @Test("Empty species fails validation")
    func testEmptySpeciesInvalid() {
        let vm = CreatePlantViewModel(plantRepo: MockPlantRepository())
        vm.name = "Monstera"
        vm.species = ""
        #expect(!vm.validate())
        #expect(vm.speciesError != nil)
    }

    @Test("Create plant with valid data succeeds")
    func testCreateSuccess() {
        let repo = MockPlantRepository()
        let vm = CreatePlantViewModel(plantRepo: repo)
        vm.name = "Fern"
        vm.species = "Nephrolepis exaltata"
        vm.wateringIntervalDays = 5
        let result = vm.createPlant()
        #expect(result)
        #expect(repo.plants.count == 1)
        #expect(repo.plants[0].name == "Fern")
        #expect(repo.plants[0].wateringIntervalDays == 5)
    }

    @Test("Create plant with NFC tag ID")
    func testCreateWithNfcTag() {
        let repo = MockPlantRepository()
        let vm = CreatePlantViewModel(plantRepo: repo)
        vm.name = "Tagged Plant"
        vm.species = "Testus plantus"
        vm.prefillNfcTag("TAG999")
        let result = vm.createPlant()
        #expect(result)
        #expect(repo.plants[0].nfcTagId == "TAG999")
    }

    @Test("Default watering interval is 7 days")
    func testDefaultInterval() {
        let vm = CreatePlantViewModel(plantRepo: MockPlantRepository())
        #expect(vm.wateringIntervalDays == 7)
    }

    @Test("Create without validation fails")
    func testCreateWithoutValidData() {
        let repo = MockPlantRepository()
        let vm = CreatePlantViewModel(plantRepo: repo)
        vm.name = ""
        vm.species = ""
        let result = vm.createPlant()
        #expect(!result)
        #expect(repo.plants.isEmpty)
    }
}
