import SwiftUI
import SwiftData

struct CreatePlantView: View {
    let nfcTagId: String?
    @Environment(AppRouter.self) private var router
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: CreatePlantViewModel?

    var body: some View {
        ZStack {
            BackgroundGradientView()
            ScrollView {
                VStack(spacing: 16) {
                    Text("New Plant")
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

                            FormField(label: "Species *", text: Binding(
                                get: { vm.species },
                                set: { vm.species = $0 }
                            ), error: vm.speciesError)

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
                                        ),
                                        in: 1...90)
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

                        if !vm.nfcTagId.isEmpty {
                            formCard {
                                HStack {
                                    Image(systemName: "wave.3.right")
                                        .foregroundStyle(AppColors.textSecondary)
                                    Text("NFC Tag: \(vm.nfcTagId)")
                                        .font(AppFonts.caption())
                                        .foregroundStyle(AppColors.textSecondary)
                                }
                            }
                        }

                        Button("Create Plant") {
                            if vm.createPlant() {
                                router.popToRoot()
                            }
                        }
                        .primaryButtonStyle()
                        .disabled(vm.isLoading)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100)
            }
        }
        .navigationBarHidden(false)
        .onAppear {
            if viewModel == nil {
                let vm = CreatePlantViewModel(
                    plantRepo: SwiftDataPlantRepository(modelContext: modelContext)
                )
                if let tagId = nfcTagId { vm.prefillNfcTag(tagId) }
                viewModel = vm
            }
        }
    }

    private func formCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            content()
        }
        .padding(16)
        .cardStyle()
    }
}
