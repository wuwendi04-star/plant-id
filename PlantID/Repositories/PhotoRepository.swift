import Foundation

protocol PhotoRepository {
    func insert(_ photo: Photo) throws
    func delete(_ photo: Photo) throws

    func getPhotosByPlant(_ plantId: UUID) throws -> [Photo]
    func getLatestPhoto(plantId: UUID) throws -> Photo?
    func countAll() throws -> Int
}
