import SwiftUI

struct ProfileView: View {
    @Environment(\.localizedBundle) private var bundle
    @State private var showSettings = false
    @State private var showFAQ = false
    @State private var showAbout = false

    var body: some View {
        ZStack {
            BackgroundGradientView()
            ScrollView {
                VStack(spacing: 16) {
                    Text("Profile", bundle: bundle)
                        .font(AppFonts.title(28))
                        .foregroundStyle(AppColors.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 16)

                    menuCard(
                        icon: "gearshape",
                        title: String(localized: "Settings", bundle: bundle),
                        subtitle: String(localized: "Language, notifications, appearance", bundle: bundle)
                    ) { showSettings = true }

                    menuCard(
                        icon: "questionmark.circle",
                        title: String(localized: "FAQ", bundle: bundle),
                        subtitle: String(localized: "NFC binding, watering reminders", bundle: bundle)
                    ) { showFAQ = true }

                    menuCard(
                        icon: "info.circle",
                        title: String(localized: "About", bundle: bundle),
                        subtitle: String(localized: "Version 1.0 · Plant ID", bundle: bundle)
                    ) { showAbout = true }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100)
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showSettings) { SettingsView() }
        .sheet(isPresented: $showFAQ) { FAQSheet() }
        .sheet(isPresented: $showAbout) { AboutSheet() }
    }

    private func menuCard(icon: String, title: String, subtitle: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundStyle(AppColors.textPrimary)
                    .frame(width: 36)
                VStack(alignment: .leading, spacing: 2) {
                    Text(verbatim: title)
                        .font(AppFonts.headline())
                        .foregroundStyle(AppColors.textPrimary)
                    Text(verbatim: subtitle)
                        .font(AppFonts.caption())
                        .foregroundStyle(AppColors.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppColors.textMuted)
            }
            .padding(16)
            .cardStyle()
        }
    }
}

private struct FAQSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.localizedBundle) private var bundle

    var body: some View {
        NavigationStack {
            List {
                Section(String(localized: "NFC Tags", bundle: bundle)) {
                    faqItem(
                        q: String(localized: "How do I bind an NFC tag to a plant?", bundle: bundle),
                        a: String(localized: "Tap + on the home screen, then scan your NFC tag on the NFC scan page before creating your plant.", bundle: bundle)
                    )
                    faqItem(
                        q: String(localized: "What NFC tags are supported?", bundle: bundle),
                        a: String(localized: "Any NDEF-compatible NFC tag (e.g. NTAG215, NTAG213). Tap the + button and scan your tag first.", bundle: bundle)
                    )
                }
                Section(String(localized: "Watering Reminders", bundle: bundle)) {
                    faqItem(
                        q: String(localized: "How do reminders work?", bundle: bundle),
                        a: String(localized: "Daily notifications at 8 AM remind you of plants that need watering. Make sure notifications are enabled.", bundle: bundle)
                    )
                }
            }
            .navigationTitle(Text("FAQ", bundle: bundle))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(String(localized: "Done", bundle: bundle)) { dismiss() }
                }
            }
        }
    }

    private func faqItem(q: String, a: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(verbatim: q).font(AppFonts.headline(15)).foregroundStyle(AppColors.textPrimary)
            Text(verbatim: a).font(AppFonts.body(14)).foregroundStyle(AppColors.textSecondary)
        }
        .padding(.vertical, 4)
    }
}

private struct AboutSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.localizedBundle) private var bundle

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "leaf.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(AppColors.textPrimary)
                Text("Plant ID", bundle: bundle)
                    .font(AppFonts.title())
                    .foregroundStyle(AppColors.textPrimary)
                Text("Version 1.0", bundle: bundle)
                    .font(AppFonts.body())
                    .foregroundStyle(AppColors.textSecondary)
                Text("Track your plants, log waterings, and never forget to water again.", bundle: bundle)
                    .font(AppFonts.body())
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(BackgroundGradientView())
            .navigationTitle(Text("About", bundle: bundle))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(String(localized: "Done", bundle: bundle)) { dismiss() }
                }
            }
        }
    }
}
