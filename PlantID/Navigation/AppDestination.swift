import Foundation

enum AppDestination: Hashable {
    case plantDetail(UUID)
    case createPlant(nfcTagId: String?)
    case editPlant(UUID)
    case nfcScan
    case photoTimeline(UUID)
}
