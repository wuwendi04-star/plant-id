import SwiftUI

extension View {
    func cardStyle(cornerRadius: CGFloat = 16) -> some View {
        self
            .background(AppColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(AppColors.cardBorder, lineWidth: 1)
            )
    }

    func primaryButtonStyle() -> some View {
        self
            .font(AppFonts.headline())
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(AppColors.textPrimary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    func dangerButtonStyle() -> some View {
        self
            .font(AppFonts.headline())
            .foregroundStyle(AppColors.danger)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(AppColors.dangerBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
