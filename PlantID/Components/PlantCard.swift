import SwiftUI

struct PlantCard: View {
    let plant: Plant
    let daysUntilWatering: Int?
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                PlantIllustration(iconName: plant.iconName)
                    .frame(maxWidth: .infinity)
                    .frame(height: 100)

                VStack(alignment: .leading, spacing: 4) {
                    Text(plant.name)
                        .font(AppFonts.headline())
                        .foregroundStyle(AppColors.textPrimary)
                        .lineLimit(1)

                    if !plant.species.isEmpty {
                        Text(plant.species)
                            .font(AppFonts.caption())
                            .foregroundStyle(AppColors.textSecondary)
                            .lineLimit(1)
                    }

                    if let days = daysUntilWatering {
                        StatusBadge(daysUntilWatering: days)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 10)
            }
        }
        .buttonStyle(.plain)
        .cardStyle()
    }
}

struct PlantCard_Archived: View {
    let plant: Plant
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                PlantIllustration(iconName: plant.iconName)
                    .frame(width: 56, height: 56)

                VStack(alignment: .leading, spacing: 2) {
                    Text(plant.name)
                        .font(AppFonts.headline())
                        .foregroundStyle(AppColors.textPrimary)
                    if !plant.species.isEmpty {
                        Text(plant.species)
                            .font(AppFonts.caption())
                            .foregroundStyle(AppColors.textSecondary)
                    }
                    if let archived = plant.archivedAt {
                        Text("Archived \(archived.formattedYMD)")
                            .font(AppFonts.caption())
                            .foregroundStyle(AppColors.textSecondary)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(AppColors.textSecondary)
            }
            .padding(12)
        }
        .buttonStyle(.plain)
        .cardStyle()
    }
}
