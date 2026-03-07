import BackgroundTasks
import SwiftData
import Foundation

enum BackgroundTaskService {
    static let wateringReminderIdentifier = "com.plantid.wateringReminder"

    static func registerTasks() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: wateringReminderIdentifier,
            using: nil
        ) { task in
            guard let refreshTask = task as? BGAppRefreshTask else {
                task.setTaskCompleted(success: false)
                return
            }
            handleWateringReminder(task: refreshTask)
        }
    }

    static func scheduleNextReminder() {
        let request = BGAppRefreshTaskRequest(identifier: wateringReminderIdentifier)
        request.earliestBeginDate = nextEightAM()
        try? BGTaskScheduler.shared.submit(request)
    }

    private static func handleWateringReminder(task: BGAppRefreshTask) {
        task.expirationHandler = { task.setTaskCompleted(success: false) }

        Task {
            let success = await performWateringCheck()
            scheduleNextReminder()
            task.setTaskCompleted(success: success)
        }
    }

    @MainActor
    private static func performWateringCheck() async -> Bool {
        do {
            let container = try ModelContainer(for: Plant.self, WateringLog.self, Photo.self)
            let context = ModelContext(container)
            let plantRepo = SwiftDataPlantRepository(modelContext: context)
            let wateringRepo = SwiftDataWateringLogRepository(modelContext: context)

            let plants = try plantRepo.getAllAlivePlantsSnapshot()
            let now = Date()

            for plant in plants {
                let last = try wateringRepo.getLastWatering(plantId: plant.id)
                let daysSince = last.map { now.daysSince($0.wateredAt) } ?? (plant.wateringIntervalDays + 1)
                if daysSince >= plant.wateringIntervalDays {
                    NotificationService.scheduleWateringReminder(plant: plant, daysSince: daysSince)
                }
            }
            return true
        } catch {
            return false
        }
    }

    private static func nextEightAM() -> Date {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.hour = 8
        components.minute = 0
        components.second = 0
        let today8am = Calendar.current.date(from: components) ?? Date()
        if today8am > Date() { return today8am }
        return Calendar.current.date(byAdding: .day, value: 1, to: today8am) ?? Date()
    }
}
