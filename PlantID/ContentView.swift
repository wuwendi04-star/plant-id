import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(AppRouter.self) private var router
    @Environment(NfcService.self) private var nfcService
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        @Bindable var router = router

        ZStack(alignment: .bottom) {
            BackgroundGradientView()

            TabView(selection: $router.selectedTab) {
                NavigationStack(path: $router.path) {
                    HomeView()
                        .navigationDestination(for: AppDestination.self, destination: destinationView)
                }
                .tag(TabDestination.home)

                NavigationStack {
                    CareView()
                        .navigationDestination(for: AppDestination.self, destination: destinationView)
                }
                .tag(TabDestination.care)

                NavigationStack {
                    ProfileView()
                }
                .tag(TabDestination.profile)
            }
            .toolbar(.hidden, for: .tabBar)
            .ignoresSafeArea(edges: .bottom)

            FloatingTabBar(selectedTab: $router.selectedTab)
        }
    }

    @ViewBuilder
    private func destinationView(for destination: AppDestination) -> some View {
        switch destination {
        case .plantDetail(let id):
            PlantDetailView(plantId: id)
        case .createPlant(let nfcTagId):
            CreatePlantView(nfcTagId: nfcTagId)
        case .editPlant(let id):
            EditPlantView(plantId: id)
        case .nfcScan:
            NfcScanView()
        case .photoTimeline(let id):
            PhotoTimelineView(plantId: id)
        }
    }
}
