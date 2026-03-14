import SwiftUI
import UIKit

/// Sheet presented from `PlantDetailView` to guide the user through
/// setting up a Shortcuts NFC automation for this plant.
struct LinkToShortcutView: View {
    let plantId: UUID
    let plantName: String
    @Environment(\.dismiss) private var dismiss

    private var deepLink: String {
        "plantid://plant/\(plantId.uuidString)"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                BackgroundGradientView()
                ScrollView {
                    VStack(spacing: 24) {
                        headerSection
                        deepLinkCard
                        stepsCard
                        openShortcutsButton
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                }
            }
            .navigationTitle("Link NFC Tag")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(AppColors.primary.opacity(0.15))
                    .frame(width: 80, height: 80)
                Image(systemName: "link.circle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(AppColors.primary)
            }
            Text("Link \(plantName) to an NFC Tag")
                .font(AppFonts.headline())
                .foregroundStyle(AppColors.textPrimary)
                .multilineTextAlignment(.center)
            Text("Use Apple Shortcuts to open this plant automatically when you tap your NFC tag.")
                .font(AppFonts.body())
                .foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Deep link card

    private var deepLinkCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Your plant's link")
                .font(AppFonts.caption())
                .foregroundStyle(AppColors.textSecondary)
            HStack {
                Text(deepLink)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(AppColors.textPrimary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Spacer()
                Button {
                    UIPasteboard.general.string = deepLink
                } label: {
                    Image(systemName: "doc.on.doc")
                        .foregroundStyle(AppColors.primary)
                }
                .buttonStyle(.plain)
            }
            .padding(12)
            .background(AppColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .padding(16)
        .cardStyle()
    }

    // MARK: - Steps card

    private var stepsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Setup Steps")
                .font(AppFonts.headline())
                .foregroundStyle(AppColors.textPrimary)
            stepRow(number: 1, title: "Open Shortcuts",
                    detail: "Tap the button below to open the Apple Shortcuts app.")
            stepRow(number: 2, title: "Create an Automation",
                    detail: "Tap Automation → + → NFC → scan your physical NFC tag → Next.")
            stepRow(number: 3, title: "Add Action",
                    detail: "Search \"Open Plant in PlantID\", select \(plantName), then tap Done.")
            stepRow(number: 4, title: "Test it",
                    detail: "Tap the NFC tag — PlantID should open directly to \(plantName).")
        }
        .padding(16)
        .cardStyle()
    }

    private func stepRow(number: Int, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(AppColors.primary)
                    .frame(width: 28, height: 28)
                Text("\(number)")
                    .font(AppFonts.caption())
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppFonts.body())
                    .fontWeight(.semibold)
                    .foregroundStyle(AppColors.textPrimary)
                Text(detail)
                    .font(AppFonts.caption())
                    .foregroundStyle(AppColors.textSecondary)
            }
            Spacer()
        }
    }

    // MARK: - Open Shortcuts button

    private var openShortcutsButton: some View {
        Button("Open Shortcuts App") {
            if let url = URL(string: "shortcuts://") {
                UIApplication.shared.open(url)
            }
        }
        .primaryButtonStyle()
    }
}
