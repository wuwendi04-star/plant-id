import SwiftUI

struct WaterConfirmSheet: View {
    let plantName: String
    let onWaterOnly: () -> Void
    let onWaterWithPhoto: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            dragIndicator

            VStack(spacing: 20) {
                Image(systemName: "drop.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(AppColors.primary)
                    .padding(.top, 8)

                Text("Water \(plantName)?")
                    .font(AppFonts.title)
                    .foregroundStyle(AppColors.textPrimary)

                Text("Record a watering session for this plant.")
                    .font(AppFonts.body)
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.center)

                VStack(spacing: 12) {
                    Button(action: onWaterWithPhoto) {
                        Label("Water with Photo", systemImage: "camera.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .primaryButtonStyle()

                    Button(action: onWaterOnly) {
                        Label("Water Only", systemImage: "drop.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .foregroundStyle(AppColors.primary)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(AppColors.primary.opacity(0.1))
                    )
                    .buttonStyle(.plain)

                    Button("Cancel", action: onDismiss)
                        .foregroundStyle(AppColors.textSecondary)
                        .font(AppFonts.body)
                        .padding(.top, 4)
                }
            }
            .padding(24)
        }
        .background(AppColors.background)
        .presentationDetents([.medium])
        .presentationDragIndicator(.hidden)
    }

    private var dragIndicator: some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(AppColors.textSecondary.opacity(0.3))
            .frame(width: 36, height: 5)
            .padding(.top, 12)
    }
}
