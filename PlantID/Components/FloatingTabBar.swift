import SwiftUI

struct FloatingTabBar: View {
    @Binding var selected: TabDestination
    let onAddPlant: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            tabButton(destination: .home, icon: "house.fill", label: "Home")
            Spacer()
            addButton()
            Spacer()
            tabButton(destination: .care, icon: "drop.fill", label: "Care")
            Spacer()
            tabButton(destination: .profile, icon: "person.fill", label: "Profile")
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 30)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.12), radius: 16, y: 4)
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 20)
    }

    private func tabButton(destination: TabDestination, icon: String, label: String) -> some View {
        Button {
            selected = destination
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                Text(label)
                    .font(AppFonts.caption())
            }
            .foregroundStyle(selected == destination ? AppColors.primary : AppColors.textSecondary)
            .frame(minWidth: 60)
        }
        .buttonStyle(.plain)
    }

    private func addButton() -> some View {
        Button(action: onAddPlant) {
            ZStack {
                Circle()
                    .fill(AppColors.primary)
                    .frame(width: 56, height: 56)
                    .shadow(color: AppColors.primary.opacity(0.4), radius: 8, y: 4)
                Image(systemName: "plus")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.white)
            }
        }
        .buttonStyle(.plain)
        .offset(y: -12)
        .accessibilityLabel("Add Plant")
    }
}
