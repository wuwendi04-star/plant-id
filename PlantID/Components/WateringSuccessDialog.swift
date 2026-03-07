import SwiftUI

struct WateringSuccessDialog: View {
    let plantName: String
    let nextWateringDays: Int
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture(perform: onDismiss)

            VStack(spacing: 20) {
                successIcon

                Text("Watered!")
                    .font(AppFonts.title)
                    .foregroundStyle(AppColors.textPrimary)

                Text("\(plantName) has been watered.")
                    .font(AppFonts.body)
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.center)

                Text("Next watering in \(nextWateringDays) day\(nextWateringDays == 1 ? "" : "s")")
                    .font(AppFonts.body)
                    .foregroundStyle(AppColors.primary)
                    .fontWeight(.medium)

                Button("Done", action: onDismiss)
                    .primaryButtonStyle()
                    .frame(maxWidth: .infinity)
            }
            .padding(28)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(AppColors.surface)
                    .shadow(color: .black.opacity(0.2), radius: 20)
            )
            .padding(.horizontal, 40)
        }
    }

    private var successIcon: some View {
        ZStack {
            Circle()
                .fill(AppColors.primary.opacity(0.15))
                .frame(width: 80, height: 80)
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(AppColors.primary)
        }
    }
}
