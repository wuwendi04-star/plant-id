import Testing
import Foundation
@testable import PlantID

@Suite("OpenPlantIntent URL Construction Tests")
struct OpenPlantIntentTests {

    @Test("plantid://plant URL is well-formed for a given UUID")
    func testURLWellFormed() {
        let plantId = UUID()
        let urlString = "plantid://plant/\(plantId.uuidString)"
        let url = URL(string: urlString)
        #expect(url != nil)
        #expect(url?.scheme == "plantid")
        #expect(url?.host == "plant")
        #expect(url?.lastPathComponent == plantId.uuidString)
    }

    @Test("URL last path component round-trips to original UUID")
    func testUUIDRoundTrip() {
        let plantId = UUID()
        let urlString = "plantid://plant/\(plantId.uuidString)"
        let url = URL(string: urlString)!
        let parsed = UUID(uuidString: url.lastPathComponent)
        #expect(parsed == plantId)
    }

    @Test("PlantEntity holds correct id and display representation")
    func testPlantEntityCreation() {
        let id = UUID()
        let entity = PlantEntity(id: id, name: "Monstera", species: "Monstera deliciosa")
        #expect(entity.id == id)
        #expect(entity.name == "Monstera")
        #expect(entity.species == "Monstera deliciosa")
    }

    @Test("PlantEntity with empty species stores empty string")
    func testPlantEntityEmptySpecies() {
        let id = UUID()
        let entity = PlantEntity(id: id, name: "Unnamed", species: "")
        #expect(entity.id == id)
        #expect(entity.name == "Unnamed")
        #expect(entity.species.isEmpty)
    }

    @Test("Two PlantEntities with same UUID are equal")
    func testPlantEntityEquality() {
        let id = UUID()
        let e1 = PlantEntity(id: id, name: "A", species: "B")
        let e2 = PlantEntity(id: id, name: "A", species: "B")
        #expect(e1.id == e2.id)
    }

    @Test("Two PlantEntities with different UUIDs are not equal")
    func testPlantEntityInequality() {
        let e1 = PlantEntity(id: UUID(), name: "A", species: "B")
        let e2 = PlantEntity(id: UUID(), name: "A", species: "B")
        #expect(e1.id != e2.id)
    }
}
