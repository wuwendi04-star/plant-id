import SwiftUI

struct StatusBadge: View {
    let daysUntilWatering: Int

    private var config: (text: String, color: Color) {
        if daysUntilWatering < 0 {
            return ("Overdue \(-daysUntilWatering)d", AppColors.urgencyOverdue)
        } else if daysUntilWatering == 0 {
            return ("Water Today", AppColors.urgencyDueToday)
        } else {
            return ("In \(daysUntilWatering)d", AppColors.urgencyOK)
        }
    }

    var body: some View {
        Text(config.text)
            .font(AppFonts.badge())
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                Capsule().fill(config.color)
            )
    }
}

struct PlantStatusBadge: View {
    let status: String

    private var config: (text: String, color: Color) {
        switch status {
        case "dormant": return ("Dormant", .blue)
        case "sick": return ("Sick", .orange)
        case "archived": return ("Archived", AppColors.textSecondary)
        default: return ("Healthy", AppColors.urgencyOK)
        }
    }

    var body: some View {
        Text(config.text)
            .font(AppFonts.badge())
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                Capsule().fill(config.color)
            )
    }
}
