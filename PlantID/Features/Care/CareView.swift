import SwiftUI
import SwiftData

struct CareView: View {
    @Environment(AppRouter.self) private var router
    @Environment(\.modelContext) private var modelContext
    @Environment(\.localizedBundle) private var bundle
    @State private var viewModel: CareViewModel?

    var body: some View {
        ZStack {
            BackgroundGradientView()
            VStack(spacing: 0) {
                Text("Care", bundle: bundle)
                    .font(AppFonts.title(28))
                    .foregroundStyle(AppColors.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 12)

                if viewModel?.isLoading == true {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else if let vm = viewModel, vm.careItems.isEmpty {
                    allHealthyState
                } else {
                    careList
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            if viewModel == nil {
                viewModel = CareViewModel(
                    plantRepo: SwiftDataPlantRepository(modelContext: modelContext),
                    wateringLogRepo: SwiftDataWateringLogRepository(modelContext: modelContext)
                )
            }
            viewModel?.loadData()
        }
    }

    @ViewBuilder
    private var careList: some View {
        ScrollView {
            VStack(spacing: 12) {
                let overdueItems = viewModel?.careItems.filter(\.isOverdue) ?? []
                let todayItems = viewModel?.careItems.filter(\.isDueToday) ?? []
                let okItems = viewModel?.careItems.filter { !$0.needsAttention } ?? []

                if !overdueItems.isEmpty {
                    sectionHeader(String(localized: "Overdue", bundle: bundle), color: AppColors.urgencyOverdue)
                    ForEach(overdueItems) { item in careRow(item) }
                }
                if !todayItems.isEmpty {
                    sectionHeader(String(localized: "Due Today", bundle: bundle), color: AppColors.urgencyDueToday)
                    ForEach(todayItems) { item in careRow(item) }
                }
                if !okItems.isEmpty {
                    sectionHeader(String(localized: "Coming Up", bundle: bundle), color: AppColors.urgencyOK)
                    ForEach(okItems) { item in careRow(item) }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 100)
        }
    }

    private func sectionHeader(_ title: String, color: Color) -> some View {
        Text(verbatim: title)
            .font(AppFonts.badge())
            .fontWeight(.semibold)
            .foregroundStyle(color)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 8)
    }

    private func careRow(_ item: PlantCareItem) -> some View {
        HStack(spacing: 12) {
            PlantIllustration(iconName: item.plant.iconName)
                .frame(width: 48, height: 48)
                .cardStyle(cornerRadius: 12)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.plant.name)
                    .font(AppFonts.headline())
                    .foregroundStyle(AppColors.textPrimary)
                Text(item.isOverdue
                    ? "Overdue by \(-item.daysUntilDue) day\(-item.daysUntilDue == 1 ? "" : "s")"
                    : item.isDueToday
                        ? String(localized: "Water today", bundle: bundle)
                        : "In \(item.daysUntilDue) days"
                )
                .font(AppFonts.caption())
                .foregroundStyle(item.isOverdue ? AppColors.urgencyOverdue : AppColors.textSecondary)
            }

            Spacer()

            Button(String(localized: "View", bundle: bundle)) {
                router.navigateToPlantDetail(item.plant.id)
            }
            .font(AppFonts.caption())
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(AppColors.textPrimary)
            .foregroundStyle(.white)
            .clipShape(Capsule())
        }
        .padding(12)
        .cardStyle()
    }

    private var allHealthyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(AppColors.urgencyOK)
            Text("All plants are healthy!", bundle: bundle)
                .font(AppFonts.headline())
                .foregroundStyle(AppColors.textPrimary)
            Spacer()
        }
    }
}
