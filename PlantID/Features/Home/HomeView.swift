import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(AppRouter.self) private var router
    @Environment(\.modelContext) private var modelContext

    @State private var viewModel: HomeViewModel?

    private var vm: HomeViewModel {
        if let vm = viewModel { return vm }
        let vm = HomeViewModel(
            plantRepo: SwiftDataPlantRepository(modelContext: modelContext),
            wateringLogRepo: SwiftDataWateringLogRepository(modelContext: modelContext)
        )
        return vm
    }

    var body: some View {
        ZStack {
            BackgroundGradientView()
            VStack(spacing: 0) {
                headerRow
                tabPicker
                plantGrid
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            if viewModel == nil {
                viewModel = HomeViewModel(
                    plantRepo: SwiftDataPlantRepository(modelContext: modelContext),
                    wateringLogRepo: SwiftDataWateringLogRepository(modelContext: modelContext)
                )
            }
            viewModel?.loadData()
        }
    }

    private var headerRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("My Plants")
                    .font(AppFonts.title(28))
                    .foregroundStyle(AppColors.textPrimary)
                Text("\(viewModel?.alivePlants.count ?? 0) plants")
                    .font(AppFonts.caption())
                    .foregroundStyle(AppColors.textSecondary)
            }
            Spacer()
            Button {
                router.navigateToNfcScan()
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(AppColors.textPrimary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }

    private var tabPicker: some View {
        HStack(spacing: 0) {
            tabButton(title: "Alive", index: 0)
            tabButton(title: "Archived", index: 1)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 12)
    }

    private func tabButton(title: String, index: Int) -> some View {
        let selected = (viewModel?.selectedTab ?? 0) == index
        return Button {
            viewModel?.selectedTab = index
        } label: {
            Text(title)
                .font(AppFonts.body())
                .fontWeight(selected ? .semibold : .regular)
                .foregroundStyle(selected ? AppColors.textPrimary : AppColors.textMuted)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    selected ? AppColors.cardBackground : Color.clear
                )
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    @ViewBuilder
    private var plantGrid: some View {
        let plants = (viewModel?.selectedTab ?? 0) == 0
            ? (viewModel?.alivePlants ?? [])
            : (viewModel?.archivedPlants ?? [])
        let daysMap = viewModel?.daysUntilWateringMap ?? [:]

        if plants.isEmpty {
            emptyState
        } else {
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(plants) { plant in
                        PlantCard(plant: plant, daysUntilWatering: daysMap[plant.id]) {
                            router.navigateToPlantDetail(plant.id)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 100)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "leaf")
                .font(.system(size: 48))
                .foregroundStyle(AppColors.textMuted)
            Text("No plants yet")
                .font(AppFonts.headline())
                .foregroundStyle(AppColors.textSecondary)
            Text("Tap + to add your first plant")
                .font(AppFonts.body())
                .foregroundStyle(AppColors.textMuted)
            Spacer()
        }
    }
}
