import Foundation

extension Date {

    func formatted(dateStyle: DateFormatter.Style = .medium,
                   timeStyle: DateFormatter.Style = .none) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = dateStyle
        formatter.timeStyle = timeStyle
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter.string(from: self)
    }

    func formatted(with format: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter.string(from: self)
    }

    func adding(days: Int) -> Date? {
        return Calendar.current.date(byAdding: .day, value: days, to: self)
    }

    func adding(hours: Int) -> Date? {
        return Calendar.current.date(byAdding: .hour, value: hours, to: self)
    }

    func adding(minutes: Int) -> Date? {
        return Calendar.current.date(byAdding: .minute, value: minutes, to: self)
    }

    var isToday: Bool {
        return Calendar.current.isDateInToday(self)
    }

    var isYesterday: Bool {
        return Calendar.current.isDateInYesterday(self)
    }

    var isThisWeek: Bool {
        return Calendar.current.isDate(self, equalTo: Date(), toGranularity: .weekOfYear)
    }

    var startOfDay: Date {
        return Calendar.current.startOfDay(for: self)
    }

    var endOfDay: Date? {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfDay)
    }

    var ageInYears: Int {
        return Calendar.current.dateComponents([.year], from: self, to: Date()).year ?? 0
    }

    var ageInMonths: Int {
        return Calendar.current.dateComponents([.month], from: self, to: Date()).month ?? 0
    }

    var ageInDays: Int {
        return Calendar.current.dateComponents([.day], from: self, to: Date()).day ?? 0
    }

    var relativeTimeString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter.localizedString(for: self, relativeTo: Date())
    }

    var shortRelativeTimeString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}
