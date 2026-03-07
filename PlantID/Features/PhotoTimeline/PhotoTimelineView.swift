import SwiftUI
import SwiftData

struct PhotoTimelineView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppRouter.self) private var router

    let plantId: UUID
    let plantName: String

    @State private var vm: PhotoTimelineViewModel?
    @State private var lightboxPhoto: Photo?

    private var viewModel: PhotoTimelineViewModel {
        if let existing = vm { return existing }
        let repos = makeRepos()
        let newVM = PhotoTimelineViewModel(
            plantRepo: repos.plant,
            photoRepo: repos.photo,
            wateringLogRepo: repos.watering
        )
        return newVM
    }

    var body: some View {
        ZStack {
            BackgroundGradientView()
            if let vm {
                VStack(spacing: 0) {
                    statsBar(vm: vm)
                    filterBar(vm: vm)
                    if vm.groupedPhotos.isEmpty {
                        emptyState(vm: vm)
                    } else {
                        photoList(vm: vm)
                    }
                }
            }
        }
        .navigationTitle(plantName)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if vm == nil {
                let repos = makeRepos()
                vm = PhotoTimelineViewModel(
                    plantRepo: repos.plant,
                    photoRepo: repos.photo,
                    wateringLogRepo: repos.watering
                )
                vm?.loadData(plantId: plantId)
            }
        }
        .sheet(item: $lightboxPhoto) { photo in
            PhotoLightbox(photo: photo)
        }
    }

    // MARK: - Sub-views

    private func statsBar(vm: PhotoTimelineViewModel) -> some View {
        HStack(spacing: 24) {
            statItem(label: "Photos", value: "\(vm.allPhotos.count)")
            statItem(label: "Waterings", value: "\(vm.totalWaterings)")
            statItem(label: "Days Kept", value: "\(vm.daysKept)")
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 24)
        .background(.ultraThinMaterial)
    }

    private func statItem(label: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(AppFonts.headline())
                .foregroundStyle(AppColors.primary)
            Text(label)
                .font(AppFonts.caption())
                .foregroundStyle(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func filterBar(vm: PhotoTimelineViewModel) -> some View {
        HStack(spacing: 0) {
            ForEach(PhotoFilter.allCases, id: \.self) { filter in
                Button {
                    vm.selectedFilter = filter
                } label: {
                    Text(filter.rawValue)
                        .font(AppFonts.body())
                        .fontWeight(vm.selectedFilter == filter ? .semibold : .regular)
                        .foregroundStyle(vm.selectedFilter == filter ? AppColors.primary : AppColors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .overlay(alignment: .bottom) {
                            if vm.selectedFilter == filter {
                                Rectangle()
                                    .fill(AppColors.primary)
                                    .frame(height: 2)
                            }
                        }
                }
            }
        }
        .background(.ultraThinMaterial)
    }

    private func emptyState(vm: PhotoTimelineViewModel) -> some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "photo.on.rectangle")
                .font(.system(size: 56))
                .foregroundStyle(AppColors.textSecondary.opacity(0.5))
            Text(emptyMessage(for: vm.selectedFilter))
                .font(AppFonts.body())
                .foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
        }
    }

    private func emptyMessage(for filter: PhotoFilter) -> String {
        switch filter {
        case .all: return "No photos yet. Take a photo next time you water!"
        case .watering: return "No watering photos yet."
        case .manual: return "No manual photos yet."
        }
    }

    private func photoList(vm: PhotoTimelineViewModel) -> some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0, pinnedViews: [.sectionHeaders]) {
                ForEach(vm.groupedPhotos) { group in
                    Section {
                        photoGrid(photos: group.photos)
                    } header: {
                        monthHeader(date: group.month)
                    }
                }
            }
            .padding(.bottom, 100)
        }
    }

    private func monthHeader(date: Date) -> some View {
        Text(date.formattedMonthYear)
            .font(AppFonts.headline())
            .foregroundStyle(AppColors.textPrimary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.ultraThinMaterial)
    }

    private func photoGrid(photos: [Photo]) -> some View {
        let columns = [GridItem(.flexible(), spacing: 2), GridItem(.flexible(), spacing: 2), GridItem(.flexible(), spacing: 2)]
        return LazyVGrid(columns: columns, spacing: 2) {
            ForEach(photos) { photo in
                photoThumbnail(photo: photo)
            }
        }
    }

    private func photoThumbnail(photo: Photo) -> some View {
        Button {
            lightboxPhoto = photo
        } label: {
            GeometryReader { geo in
                if let image = loadImage(path: photo.filePath) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.width)
                        .clipped()
                } else {
                    Rectangle()
                        .fill(AppColors.surface)
                        .frame(width: geo.size.width, height: geo.size.width)
                        .overlay {
                            Image(systemName: "photo")
                                .foregroundStyle(AppColors.textSecondary)
                        }
                }
            }
            .aspectRatio(1, contentMode: .fit)
        }
    }

    // MARK: - Helpers

    private func loadImage(path: String) -> UIImage? {
        guard !path.isEmpty else { return nil }
        let url = URL(fileURLWithPath: path)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }

    private func makeRepos() -> (plant: PlantRepository, photo: PhotoRepository, watering: WateringLogRepository) {
        let plant = SwiftDataPlantRepository(modelContext: modelContext)
        let photo = SwiftDataPhotoRepository(modelContext: modelContext)
        let watering = SwiftDataWateringLogRepository(modelContext: modelContext)
        return (plant, photo, watering)
    }
}
