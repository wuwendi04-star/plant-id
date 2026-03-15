import Foundation

@MainActor
protocol WateringLogRepository {
    func insert(_ log: WateringLog) throws
    func delete(_ log: WateringLog) throws

    func getLogsByPlant(_ plantId: UUID) throws -> [WateringLog]
    func getLastWatering(plantId: UUID) throws -> WateringLog?
    func countByPlant(_ plantId: UUID) throws -> Int
    func countAll() throws -> Int
}
