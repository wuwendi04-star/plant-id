import Foundation

extension Date {
    var daysSinceNow: Int {
        let diff = Calendar.current.dateComponents([.day], from: self, to: Date())
        return max(diff.day ?? 0, 0)
    }

    func daysSince(_ other: Date) -> Int {
        let diff = Calendar.current.dateComponents([.day], from: other, to: self)
        return max(diff.day ?? 0, 0)
    }

    var formattedYMD: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: self)
    }

    var formattedMonthYear: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: self)
    }

    var isSameMonthAs: (Date) -> Bool {
        { other in
            Calendar.current.isDate(self, equalTo: other, toGranularity: .month)
        }
    }
}
