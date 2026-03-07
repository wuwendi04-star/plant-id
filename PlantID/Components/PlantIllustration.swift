import SwiftUI

/// Renders the plant icon. Uses bundled asset images named after `iconName`.
/// Falls back to a leaf system icon if the asset is not found.
struct PlantIllustration: View {
    let iconName: String

    var body: some View {
        if UIImage(named: iconName) != nil {
            Image(iconName)
                .resizable()
                .scaledToFit()
                .padding(8)
        } else {
            Image(systemName: systemFallback(for: iconName))
                .resizable()
                .scaledToFit()
                .foregroundStyle(AppColors.primary)
                .padding(12)
        }
    }

    private func systemFallback(for name: String) -> String {
        switch name {
        case "cactus": return "camera.macro"
        case "fern": return "leaf"
        case "orchid": return "camera.macro.circle"
        case "palm": return "leaf.circle"
        case "succulent": return "drop.circle"
        case "bonsai": return "tree"
        case "rose": return "heart.circle"
        case "sunflower": return "sun.max"
        default: return "leaf.fill"  // monstera + others
        }
    }
}
