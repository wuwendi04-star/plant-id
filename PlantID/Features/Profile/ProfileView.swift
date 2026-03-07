import SwiftUI

struct ProfileView: View {
    @State private var showFAQ = false
    @State private var showAbout = false

    var body: some View {
        ZStack {
            BackgroundGradientView()
            ScrollView {
                VStack(spacing: 16) {
                    Text("Profile")
                        .font(AppFonts.title(28))
                        .foregroundStyle(AppColors.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 16)

                    menuCard(
                        icon: "questionmark.circle",
                        title: "FAQ",
                        subtitle: "NFC binding, watering reminders"
                    ) { showFAQ = true }

                    menuCard(
                        icon: "info.circle",
                        title: "About",
                        subtitle: "Version 1.0 · Plant ID"
                    ) { showAbout = true }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100)
            }
        }
        .navigationBarHidden(true)
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
                    Text(title)
                        .font(AppFonts.headline())
                        .foregroundStyle(AppColors.textPrimary)
                    Text(subtitle)
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

    var body: some View {
        NavigationStack {
            List {
                Section("NFC Tags") {
                    faqItem(
                        q: "How do I bind an NFC tag to a plant?",
                        a: "Tap + on the home screen, then scan your NFC tag on the NFC scan page before creating your plant."
                    )
                    faqItem(
                        q: "What NFC tags are supported?",
                        a: "Any NDEF-compatible NFC tag (e.g. NTAG215, NTAG213). Tap the + button and scan your tag first."
                    )
                }
                Section("Watering Reminders") {
                    faqItem(
                        q: "How do reminders work?",
                        a: "Daily notifications at 8 AM remind you of plants that need watering. Make sure notifications are enabled."
                    )
                }
            }
            .navigationTitle("FAQ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func faqItem(q: String, a: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(q).font(AppFonts.headline(15)).foregroundStyle(AppColors.textPrimary)
            Text(a).font(AppFonts.body(14)).foregroundStyle(AppColors.textSecondary)
        }
        .padding(.vertical, 4)
    }
}

private struct AboutSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "leaf.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(AppColors.textPrimary)
                Text("Plant ID")
                    .font(AppFonts.title())
                    .foregroundStyle(AppColors.textPrimary)
                Text("Version 1.0")
                    .font(AppFonts.body())
                    .foregroundStyle(AppColors.textSecondary)
                Text("Track your plants, log waterings, and never forget to water again.")
                    .font(AppFonts.body())
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(BackgroundGradientView())
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
