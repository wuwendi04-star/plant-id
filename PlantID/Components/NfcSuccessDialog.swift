import SwiftUI

struct NfcSuccessDialog: View {
    let plantName: String
    let message: String
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture(perform: onDismiss)

            VStack(spacing: 20) {
                nfcIcon

                Text("NFC Tag Linked!")
                    .font(AppFonts.title)
                    .foregroundStyle(AppColors.textPrimary)

                Text(message)
                    .font(AppFonts.body)
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.center)

                if !plantName.isEmpty {
                    Text(plantName)
                        .font(AppFonts.headline)
                        .foregroundStyle(AppColors.primary)
                }

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

    private var nfcIcon: some View {
        ZStack {
            Circle()
                .fill(AppColors.primary.opacity(0.15))
                .frame(width: 80, height: 80)
            Image(systemName: "wave.3.right.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(AppColors.primary)
        }
    }
}
