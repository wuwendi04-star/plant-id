import SwiftUI
import SwiftData

struct EditPlantView: View {
    let plantId: UUID
    @Environment(AppRouter.self) private var router
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: EditPlantViewModel?
    @State private var showArchiveSheet = false

    var body: some View {
        ZStack {
            BackgroundGradientView()
            ScrollView {
                VStack(spacing: 16) {
                    Text("Edit Plant")
                        .font(AppFonts.title(24))
                        .foregroundStyle(AppColors.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 8)

                    if let vm = viewModel {
                        IconSelector(selectedIcon: Binding(
                            get: { vm.iconName },
                            set: { vm.iconName = $0 }
                        ))

                        formCard {
                            FormField(label: "Plant Name *", text: Binding(
                                get: { vm.name },
                                set: { vm.name = $0 }
                            ), error: vm.nameError)
                            Divider()
                            FormField(label: "Species", text: Binding(
                                get: { vm.species },
                                set: { vm.species = $0 }
                            ), error: nil)
                            Divider()
                            DatePicker("Acquired Date", selection: Binding(
                                get: { vm.acquiredDate },
                                set: { vm.acquiredDate = $0 }
                            ), displayedComponents: .date)
                            .font(AppFonts.body())
                            .foregroundStyle(AppColors.textPrimary)
                        }

                        formCard {
                            HStack {
                                Text("Watering Interval")
                                    .font(AppFonts.body())
                                    .foregroundStyle(AppColors.textPrimary)
                                Spacer()
                                Stepper("\(vm.wateringIntervalDays) days",
                                        value: Binding(
                                            get: { vm.wateringIntervalDays },
                                            set: { vm.wateringIntervalDays = $0 }
                                        ), in: 1...90)
                                .font(AppFonts.body())
                            }
                        }

                        formCard {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Notes").font(AppFonts.body()).foregroundStyle(AppColors.textSecondary)
                                TextEditor(text: Binding(
                                    get: { vm.notes },
                                    set: { vm.notes = $0 }
                                ))
                                .frame(minHeight: 80)
                                .font(AppFonts.body())
                            }
                        }

                        Button("Save Changes") {
                            if vm.savePlant() { router.pop() }
                        }
                        .primaryButtonStyle()

                        dangerZone
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100)
            }
        }
        .navigationBarHidden(false)
        .onAppear {
            if viewModel == nil {
                viewModel = EditPlantViewModel(
                    plantRepo: SwiftDataPlantRepository(modelContext: modelContext)
                )
                viewModel?.loadPlant(id: plantId)
            }
        }
        .confirmationDialog("Archive this plant?", isPresented: $showArchiveSheet) {
            Button("Archive", role: .destructive) {
                if viewModel?.archivePlant() == true { router.popToRoot() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("The plant will be moved to your archived list.")
        }
    }

    private var dangerZone: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Danger Zone")
                .font(AppFonts.badge())
                .fontWeight(.semibold)
                .foregroundStyle(AppColors.danger)
            Button("Archive This Plant") { showArchiveSheet = true }
                .dangerButtonStyle()
        }
        .padding(16)
        .cardStyle()
    }

    private func formCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) { content() }
            .padding(16)
            .cardStyle()
    }
}
