import Foundation

protocol PlantRepository {
    func insert(_ plant: Plant) throws
    func update() throws
    func delete(_ plant: Plant) throws

    func getAlivePlants() throws -> [Plant]
    func getArchivedPlants() throws -> [Plant]
    func getPlantById(_ id: UUID) throws -> Plant?
    func getPlantByNfcTag(_ tagId: String) throws -> Plant?
    func getAllNfcTagIds() throws -> [String]
    func getAllAlivePlantsSnapshot() throws -> [Plant]
    func countAlivePlants() throws -> Int
}
