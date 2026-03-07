import SwiftUI

enum AppGradients {
    static let background = LinearGradient(
        colors: [AppColors.backgroundTop, AppColors.backgroundMid, AppColors.backgroundBottom],
        startPoint: .top,
        endPoint: .bottom
    )
}

struct BackgroundGradientView: View {
    var body: some View {
        AppGradients.background
            .ignoresSafeArea()
    }
}
