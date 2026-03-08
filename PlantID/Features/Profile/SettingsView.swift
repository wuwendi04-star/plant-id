import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(LanguageManager.self) private var languageManager
    @Environment(AppearanceManager.self) private var appearanceManager

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
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(AppColors.primary)
                }
            }
        }
        .alert("Reset App Data?", isPresented: $showResetConfirmation) {
            Button("Reset", role: .destructive) { resetAllData() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete all your plant data. This action cannot be undone.")
        }
        .alert("Reset Failed", isPresented: $showResetError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Could not delete all plant data. Please try again.")
        }
        .alert("Notifications Disabled", isPresented: $showPermissionDeniedAlert) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Allow notifications in Settings to enable daily plant care reminders.")
        }
    }

    // MARK: - Sections

    private var languageSection: some View {
        Section(header: Text("LANGUAGE")) {
            Picker("Language", selection: Binding(
                get: { languageManager.languageCode },
                set: { languageManager.languageCode = $0 }
            )) {
                Text("English").tag("en")
                Text("Chinese").tag("zh-Hans")
            }
            .pickerStyle(.segmented)
        }
    }

    private var notificationsSection: some View {
        Section(header: Text("NOTIFICATIONS")) {
            Toggle("Daily Reminder", isOn: Binding(
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
                    "Reminder Time",
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
        Section(header: Text("APPEARANCE")) {
            Picker("Appearance", selection: Binding(
                get: { appearanceManager.appearanceMode },
                set: { appearanceManager.appearanceMode = $0 }
            )) {
                Text("System").tag("system")
                Text("Light").tag("light")
                Text("Dark").tag("dark")
            }
            .pickerStyle(.segmented)
        }
    }

    private var dataSection: some View {
        Section(header: Text("DATA")) {
            Button("Reset App Data") {
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
