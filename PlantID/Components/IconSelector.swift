import SwiftUI

private let availableIcons = [
    "monstera", "cactus", "fern", "orchid",
    "palm", "succulent", "bonsai", "rose", "sunflower"
]

struct IconSelector: View {
    @Binding var selectedIcon: String

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Plant Icon")
                .font(AppFonts.headline())
                .foregroundStyle(AppColors.textPrimary)

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(availableIcons, id: \.self) { icon in
                    iconCell(name: icon)
                }
            }
        }
    }

    private func iconCell(name: String) -> some View {
        Button {
            selectedIcon = name
        } label: {
            PlantIllustration(iconName: name)
                .frame(height: 72)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(selectedIcon == name ? AppColors.primary.opacity(0.15) : AppColors.surface)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    selectedIcon == name ? AppColors.primary : Color.clear,
                                    lineWidth: 2
                                )
                        )
                )
        }
        .buttonStyle(.plain)
    }
}
