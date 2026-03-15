import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(LanguageManager.self) private var languageManager
    @Environment(AppearanceManager.self) private var appearanceManager
    @Environment(\.localizedBundle) private var bundle

    @AppStorage("notifications_enabled") private var notificationsEnabled: Bool = true
    @AppStorage("reminder_hour") private var reminderHour: Int = 8
    @AppStorage("reminder_minute") private var reminderMinute: Int = 0

    @State private var showResetConfirmation = false
    @State private var showResetError = false
    @State private var showPermissionDeniedAlert = false

    private var reminderDate: Date {
        Calendar.current.date(from: DateComponents(hour: reminderHour, minute: reminderMinute)) ?? Date()
    }

    var body: some View {
        NavigationStack {
            Form {
                languageSection
                notificationsSection
                appearanceSection
                dataSection
            }
            .navigationTitle(Text("Settings", bundle: bundle))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(String(localized: "Done", bundle: bundle)) { dismiss() }
                        .foregroundStyle(AppColors.primary)
                }
            }
        }
        .alert(String(localized: "Reset App Data?", bundle: bundle), isPresented: $showResetConfirmation) {
            Button(String(localized: "Reset", bundle: bundle), role: .destructive) { resetAllData() }
            Button(String(localized: "Cancel", bundle: bundle), role: .cancel) {}
        } message: {
            Text("This will permanently delete all your plant data. This action cannot be undone.", bundle: bundle)
        }
        .alert(String(localized: "Reset Failed", bundle: bundle), isPresented: $showResetError) {
            Button(String(localized: "Cancel", bundle: bundle), role: .cancel) {}
        } message: {
            Text("Could not delete all plant data. Please try again.", bundle: bundle)
        }
        .alert(String(localized: "Notifications Disabled", bundle: bundle), isPresented: $showPermissionDeniedAlert) {
            Button(String(localized: "Open Settings", bundle: bundle)) {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button(String(localized: "Cancel", bundle: bundle), role: .cancel) {}
        } message: {
            Text("Allow notifications in Settings to enable daily plant care reminders.", bundle: bundle)
        }
    }

    // MARK: - Sections

    private var languageSection: some View {
        Section(header: Text("LANGUAGE", bundle: bundle)) {
            Picker(String(localized: "Language", bundle: bundle), selection: Binding(
                get: { languageManager.languageCode },
                set: { languageManager.languageCode = $0 }
            )) {
                Text("English", bundle: bundle).tag("en")
                Text("Chinese", bundle: bundle).tag("zh-Hans")
            }
            .pickerStyle(.segmented)
        }
    }

    private var notificationsSection: some View {
        Section(header: Text("NOTIFICATIONS", bundle: bundle)) {
            Toggle(String(localized: "Daily Reminder", bundle: bundle), isOn: Binding(
                get: { notificationsEnabled },
                set: { newValue in
                    if newValue {
                        enableNotifications()
                    } else {
                        notificationsEnabled = false
                        NotificationService.cancelAllPending()
                    }
                }
            ))
            .tint(AppColors.primary)

            if notificationsEnabled {
                DatePicker(
                    String(localized: "Reminder Time", bundle: bundle),
                    selection: Binding(
                        get: { reminderDate },
                        set: { newDate in
                            let comps = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                            reminderHour = comps.hour ?? 8
                            reminderMinute = comps.minute ?? 0
                            rescheduleNotification()
                        }
                    ),
                    displayedComponents: .hourAndMinute
                )
            }
        }
    }

    private var appearanceSection: some View {
        Section(header: Text("APPEARANCE", bundle: bundle)) {
            Picker(String(localized: "Appearance", bundle: bundle), selection: Binding(
                get: { appearanceManager.appearanceMode },
                set: { appearanceManager.appearanceMode = $0 }
            )) {
                Text("System", bundle: bundle).tag("system")
                Text("Light", bundle: bundle).tag("light")
                Text("Dark", bundle: bundle).tag("dark")
            }
            .pickerStyle(.segmented)
        }
    }

    private var dataSection: some View {
        Section(header: Text("DATA", bundle: bundle)) {
            Button(String(localized: "Reset App Data", bundle: bundle)) {
                showResetConfirmation = true
            }
            .foregroundStyle(AppColors.danger)
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }

    // MARK: - Actions

    private func enableNotifications() {
        Task {
            let granted = await NotificationService.requestPermission()
            if granted {
                notificationsEnabled = true
                rescheduleNotification()
            } else {
                notificationsEnabled = false
                showPermissionDeniedAlert = true
            }
        }
    }

    private func rescheduleNotification() {
        NotificationService.cancelAllPending()
        NotificationService.scheduleDailyReminder(hour: reminderHour, minute: reminderMinute)
    }

    private func resetAllData() {
        do {
            try modelContext.delete(model: Plant.self)
            try modelContext.delete(model: WateringLog.self)
            try modelContext.delete(model: Photo.self)
            NotificationService.cancelAllPending()
            UserDefaults.standard.removeObject(forKey: "notifications_enabled")
            UserDefaults.standard.removeObject(forKey: "reminder_hour")
            UserDefaults.standard.removeObject(forKey: "reminder_minute")
            UserDefaults.standard.set(false, forKey: "sample_data_seeded")
        } catch {
            showResetError = true
        }
    }
}
