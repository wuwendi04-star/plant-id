import SwiftUI
import SwiftData

struct PlantDetailView: View {
    let plantId: UUID
    @Environment(AppRouter.self) private var router
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: PlantDetailViewModel?
    @State private var showWaterSheet = false
    @State private var showArchiveDialog = false
    @State private var showDeleteDialog = false
    @State private var showCamera = false
    @State private var pendingWatering = false

    var body: some View {
        ZStack {
            BackgroundGradientView()
            if let vm = viewModel, let plant = vm.plant {
                ScrollView {
                    VStack(spacing: 16) {
                        heroCard(plant: plant, vm: vm)
                        wateringButton(vm: vm)
                        infoCard(plant: plant)
                        if !vm.wateringLogs.isEmpty { wateringHistory(vm: vm) }
                        photoGrid(vm: vm, plantId: plant.id)
                        archiveDeleteButtons(plant: plant, vm: vm)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100)
                }

                if vm.showWateringSuccess {
                    WateringSuccessDialog(
                        plant: plant,
                        onDismiss: { vm.dismissWateringSuccess() }
                    )
                }
            } else {
                ProgressView()
            }
        }
        .navigationBarHidden(false)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    if let id = viewModel?.plant?.id { router.navigateToEditPlant(id) }
                } label: {
                    Image(systemName: "pencil")
                }
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = PlantDetailViewModel(
                    plantRepo: SwiftDataPlantRepository(modelContext: modelContext),
                    wateringLogRepo: SwiftDataWateringLogRepository(modelContext: modelContext),
                    photoRepo: SwiftDataPhotoRepository(modelContext: modelContext)
                )
            }
            viewModel?.loadPlant(id: plantId)
        }
        .sheet(isPresented: $showWaterSheet) {
            WaterConfirmSheet(
                onWaterOnly: {
                    viewModel?.addWatering()
                    showWaterSheet = false
                },
                onWaterWithPhoto: {
                    pendingWatering = true
                    showWaterSheet = false
                    showCamera = true
                }
            )
            .presentationDetents([.medium])
        }
        .sheet(isPresented: $showCamera) {
            CameraPicker { image in
                if pendingWatering {
                    viewModel?.saveWateringWithPhoto(image: image)
                    pendingWatering = false
                } else {
                    viewModel?.savePhotoOnly(image: image)
                }
            }
        }
        .confirmationDialog("Archive Plant", isPresented: $showArchiveDialog) {
            Button("Archive", role: .destructive) {
                if viewModel?.archivePlant() == true { router.popToRoot() }
            }
            Button("Cancel", role: .cancel) {}
        } message: { Text("This plant will be moved to your archived list.") }
        .confirmationDialog("Delete Plant", isPresented: $showDeleteDialog) {
            Button("Delete Permanently", role: .destructive) {
                if viewModel?.deletePlant() == true { router.popToRoot() }
            }
            Button("Cancel", role: .cancel) {}
        } message: { Text("This will permanently delete the plant and all its data.") }
    }

    private func heroCard(plant: Plant, vm: PlantDetailViewModel) -> some View {
        HStack(spacing: 16) {
            PlantIllustration(iconName: plant.iconName)
                .frame(width: 72, height: 72)
                .cardStyle(cornerRadius: 16)
            VStack(alignment: .leading, spacing: 4) {
                Text(plant.name)
                    .font(AppFonts.title(22))
                    .foregroundStyle(AppColors.textPrimary)
                Text(plant.species)
                    .font(AppFonts.body())
                    .foregroundStyle(AppColors.textSecondary)
                HStack(spacing: 8) {
                    StatusBadge(text: "\(vm.daysKept) days", color: AppColors.statusAlive)
                    if vm.lastWateredDaysAgo >= 0 {
                        StatusBadge(text: "Watered \(vm.lastWateredDaysAgo)d ago", color: AppColors.urgencyOK)
                    }
                }
            }
            Spacer()
        }
        .padding(16)
        .cardStyle()
    }

    private func wateringButton(vm: PlantDetailViewModel) -> some View {
        Button("Water Now") { showWaterSheet = true }
            .primaryButtonStyle()
            .disabled(vm.isAddingWatering)
    }

    private func infoCard(plant: Plant) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Plant Info")
                .font(AppFonts.headline())
                .foregroundStyle(AppColors.textPrimary)
            infoRow("Acquired", value: plant.acquiredDate.formattedYMD)
            infoRow("Watering Interval", value: "\(plant.wateringIntervalDays) days")
            if !plant.notes.isEmpty {
                infoRow("Notes", value: plant.notes)
            }
            if !plant.nfcTagId.isEmpty {
                infoRow("NFC Tag", value: plant.nfcTagId)
            }
        }
        .padding(16)
        .cardStyle()
    }

    private func infoRow(_ label: String, value: String) -> some View {
        HStack(alignment: .top) {
            Text(label)
                .font(AppFonts.caption())
                .foregroundStyle(AppColors.textSecondary)
                .frame(width: 110, alignment: .leading)
            Text(value)
                .font(AppFonts.body())
                .foregroundStyle(AppColors.textPrimary)
            Spacer()
        }
    }

    private func wateringHistory(vm: PlantDetailViewModel) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Watering History")
                .font(AppFonts.headline())
                .foregroundStyle(AppColors.textPrimary)
            ForEach(Array(vm.wateringLogs.prefix(5))) { log in
                HStack {
                    Circle()
                        .fill(AppColors.urgencyOK)
                        .frame(width: 8, height: 8)
                    Text(log.wateredAt.formattedYMD)
                        .font(AppFonts.body())
                        .foregroundStyle(AppColors.textPrimary)
                    Spacer()
                    if !log.photoPath.isEmpty {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(AppColors.textMuted)
                    }
                }
            }
        }
        .padding(16)
        .cardStyle()
    }

    private func photoGrid(vm: PlantDetailViewModel, plantId: UUID) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Photos (\(vm.photos.count))")
                    .font(AppFonts.headline())
                    .foregroundStyle(AppColors.textPrimary)
                Spacer()
                if vm.photos.count > 5 {
                    Button("See All") { router.navigateToPhotoTimeline(plantId) }
                        .font(AppFonts.caption())
                        .foregroundStyle(AppColors.textSecondary)
                }
                Button {
                    pendingWatering = false
                    showCamera = true
                } label: {
                    Image(systemName: "camera")
                        .foregroundStyle(AppColors.textSecondary)
                }
            }

            if vm.photos.isEmpty {
                Text("No photos yet. Tap the camera icon to add one.")
                    .font(AppFonts.caption())
                    .foregroundStyle(AppColors.textMuted)
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 4) {
                    ForEach(vm.photos.prefix(5)) { photo in
                        if let image = UIImage(contentsOfFile: photo.filePath) {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(height: 80)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }
            }
        }
        .padding(16)
        .cardStyle()
    }

    private func archiveDeleteButtons(plant: Plant, vm: PlantDetailViewModel) -> some View {
        VStack(spacing: 8) {
            if plant.isAlive {
                Button("Archive Plant") { showArchiveDialog = true }
                    .dangerButtonStyle()
            } else {
                Button("Delete Permanently") { showDeleteDialog = true }
                    .dangerButtonStyle()
            }
        }
        .padding(16)
        .cardStyle()
    }
}

import UIKit
