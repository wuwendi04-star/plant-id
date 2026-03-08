import SwiftUI
import SwiftData
import UserNotifications

@main
struct PlantIDApp: App {
    @State private var router = AppRouter()
    @State private var nfcService = NfcService()
    @State private var nfcViewModel: NfcScanViewModel?
    @State private var languageManager = LanguageManager()
    @State private var appearanceManager = AppearanceManager()

    let modelContainer: ModelContainer

    init() {
        do {
            modelContainer = try ModelContainer(for: Plant.self, WateringLog.self, Photo.self)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
        BackgroundTaskService.registerTasks()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(modelContainer)
                .environment(router)
                .environment(nfcService)
                .environment(languageManager)
                .environment(appearanceManager)
                .environment(\.locale, languageManager.locale)
                .preferredColorScheme(appearanceManager.colorScheme)
                .task {
                    await setupApp()
                }
                .onOpenURL { url in
                    handleDeepLink(url)
                }
                .onReceive(
                    NotificationCenter.default.publisher(
                        for: UIApplication.didFinishLaunchingNotification
                    )
                ) { _ in }
        }
    }

    @MainActor
    private func setupApp() async {
        // Request notification permission and schedule daily reminder if enabled
        let notificationsEnabled = UserDefaults.standard.object(forKey: "notifications_enabled") as? Bool ?? true
        let granted = await NotificationService.requestPermission()
        if granted && notificationsEnabled {
            let hour = UserDefaults.standard.object(forKey: "reminder_hour") as? Int ?? 8
            let minute = UserDefaults.standard.object(forKey: "reminder_minute") as? Int ?? 0
            NotificationService.scheduleDailyReminder(hour: hour, minute: minute)
            BackgroundTaskService.scheduleNextReminder()
        }

        // Seed sample data on first launch
        let context = modelContainer.mainContext
        let plantRepo = SwiftDataPlantRepository(modelContext: context)
        SeedDataService.seedIfNeeded(plantRepository: plantRepo)
    }

    private func handleDeepLink(_ url: URL) {
        // plantid://nfc/{tagId}
        guard url.scheme == "plantid", url.host == "nfc" else { return }
        let tagId = url.lastPathComponent
        // Validate tag ID is hex (8-32 chars) to prevent path traversal / injection
        guard !tagId.isEmpty,
              tagId.range(of: "^[0-9A-Fa-f]{8,32}$", options: .regularExpression) != nil else { return }
        Task { @MainActor in
            let context = modelContainer.mainContext
            let plantRepo = SwiftDataPlantRepository(modelContext: context)
            if let plant = try? plantRepo.getPlantByNfcTag(tagId) {
                router.popToRoot()
                router.selectedTab = .home
                router.navigateToPlantDetail(plant.id)
            }
        }
    }
}
