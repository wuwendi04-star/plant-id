import SwiftUI

struct FormField: View {
    let label: String
    var placeholder: String = ""
    @Binding var text: String
    var isMultiline: Bool = false
    var error: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(AppFonts.caption())
                .foregroundStyle(AppColors.textSecondary)

            if isMultiline {
                TextEditor(text: $text)
                    .font(AppFonts.body())
                    .frame(minHeight: 80)
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(AppColors.surface)
                    )
            } else {
                TextField(placeholder, text: $text)
                    .font(AppFonts.body())
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(AppColors.surface)
                    )
            }
            
            if let error {
                Text(error)
                    .font(AppFonts.caption())
                    .foregroundStyle(AppColors.urgencyOverdue)
            }
        }
    }
}

struct FormSection<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(AppFonts.headline())
                .foregroundStyle(AppColors.textPrimary)
            content
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppColors.surface)
        )
    }
}

struct WateringTimeline: View {
    let logs: [WateringLog]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(logs.enumerated()), id: \.element.id) { index, log in
                HStack(alignment: .top, spacing: 12) {
                    timelineDot(isFirst: index == 0)
                    logRow(log: log)
                    Spacer()
                }
                .padding(.vertical, 6)

                if index < logs.count - 1 {
                    timelineConnector
                }
            }
        }
    }

    private func timelineDot(isFirst: Bool) -> some View {
        ZStack {
            Circle()
                .fill(isFirst ? AppColors.primary : AppColors.primary.opacity(0.3))
                .frame(width: 12, height: 12)
        }
        .frame(width: 16)
        .padding(.top, 4)
    }

    private var timelineConnector: some View {
        HStack {
            Rectangle()
                .fill(AppColors.primary.opacity(0.2))
                .frame(width: 2, height: 16)
                .padding(.leading, 7)
            Spacer()
        }
    }

    private func logRow(log: WateringLog) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(log.wateredAt.formattedYMD)
                .font(AppFonts.body())
                .foregroundStyle(AppColors.textPrimary)
            if !log.photoPath.isEmpty {
                Label("Photo attached", systemImage: "photo")
                    .font(AppFonts.caption())
                    .foregroundStyle(AppColors.textSecondary)
            }
        }
    }
}
