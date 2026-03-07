import SwiftUI
import Observation

@Observable
final class AppRouter {
    var path = NavigationPath()
    var selectedTab: TabDestination = .home

    func navigateToPlantDetail(_ id: UUID) {
        path.append(AppDestination.plantDetail(id))
    }

    func navigateToCreatePlant(nfcTagId: String? = nil) {
        path.append(AppDestination.createPlant(nfcTagId: nfcTagId))
    }

    func navigateToNfcScan() {
        path.append(AppDestination.nfcScan)
    }

    func navigateToEditPlant(_ id: UUID) {
        path.append(AppDestination.editPlant(id))
    }

    func navigateToPhotoTimeline(_ id: UUID) {
        path.append(AppDestination.photoTimeline(id))
    }

    func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    func popToRoot() {
        path = NavigationPath()
    }
}
