import SwiftUI
import SwiftData
import UserNotifications

@main
struct PlantIDApp: App {
    @State private var router = AppRouter()
    @State private var languageManager = LanguageManager()
    @State private var appearanceManager = AppearanceManager()

    let modelContainer: ModelContainer

    init() {
        do {
            modelContainer = try ModelContainer(for: Plant.self, WateringLog.self, Photo.self)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
        ModelContainerProvider.shared.configure(modelContainer)
        BackgroundTaskService.registerTasks()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(modelContainer)
                .environment(router)
                .environment(languageManager)
                .environment(appearanceManager)
                .environment(\.locale, languageManager.locale)
                .environment(\.localizedBundle, languageManager.bundle)
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
        let isUITesting = CommandLine.arguments.contains("--uitesting")

        if !isUITesting {
            // Request notification permission and schedule daily reminder if enabled
            let notificationsEnabled = UserDefaults.standard.object(forKey: "notifications_enabled") as? Bool ?? true
            let granted = await NotificationService.requestPermission()
            if granted && notificationsEnabled {
                let hour = UserDefaults.standard.object(forKey: "reminder_hour") as? Int ?? 8
                let minute = UserDefaults.standard.object(forKey: "reminder_minute") as? Int ?? 0
                NotificationService.scheduleDailyReminder(hour: hour, minute: minute)
                BackgroundTaskService.scheduleNextReminder()
            }
        }

        // Seed sample data on first launch
        let context = modelContainer.mainContext
        let plantRepo = SwiftDataPlantRepository(modelContext: context)
        SeedDataService.seedIfNeeded(plantRepository: plantRepo)
    }

    @MainActor
    private func handleDeepLink(_ url: URL) {
        guard url.scheme == "plantid" else { return }
        // Enforce exactly one path segment to prevent multi-segment injection.
        let components = url.pathComponents  // ["/" , "<segment>"]
        guard components.count == 2 else { return }
        let segment = components[1]

        switch url.host {
        case "plant":
            // plantid://plant/{UUID} — used by App Intent / Shortcuts NFC automation
            guard let uuid = UUID(uuidString: segment) else { return }
            router.popToRoot()
            router.selectedTab = .home
            router.navigateToPlantDetail(uuid)

        case "nfc":
            // plantid://nfc/{tagId} — legacy deep link written to NFC tags
            guard segment.range(of: "^[0-9A-Fa-f]{8,32}$", options: .regularExpression) != nil else { return }
            Task { @MainActor in
                let context = modelContainer.mainContext
                let plantRepo = SwiftDataPlantRepository(modelContext: context)
                do {
                    if let plant = try plantRepo.getPlantByNfcTag(segment) {
                        router.popToRoot()
                        router.selectedTab = .home
                        router.navigateToPlantDetail(plant.id)
                    }
                } catch {
                    debugPrint("[PlantIDApp] NFC deep link lookup failed: \(error)")
                }
            }

        default:
            break
        }
    }
}
