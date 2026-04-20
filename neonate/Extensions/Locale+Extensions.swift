import Foundation

extension DateFormatter {

    static var fullDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter
    }

    static var shortDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }

    static var dateTimeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        return formatter
    }

    static var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }

    static var monthDayFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.setLocalizedDateFormatFromTemplate("MMMMd")
        return formatter
    }

    static var monthYearFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.setLocalizedDateFormatFromTemplate("MMMMyyyy")
        return formatter
    }

    static var iso8601Formatter: ISO8601DateFormatter {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }
}

extension RelativeDateTimeFormatter {

    static var relativeFormatter: RelativeDateTimeFormatter {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale.current
        formatter.unitsStyle = .full
        formatter.dateTimeStyle = .named
        return formatter
    }

    static var shortRelativeFormatter: RelativeDateTimeFormatter {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale.current
        formatter.unitsStyle = .short
        formatter.dateTimeStyle = .named
        return formatter
    }

    static var abbreviatedRelativeFormatter: RelativeDateTimeFormatter {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale.current
        formatter.unitsStyle = .abbreviated
        formatter.dateTimeStyle = .numeric
        return formatter
    }
}

extension NumberFormatter {

    static var integerFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.locale = Locale.current
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter
    }

    static var decimalFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.locale = Locale.current
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 1
        return formatter
    }

    static var preciseDecimalFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.locale = Locale.current
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter
    }

    static var percentFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.locale = Locale.current
        formatter.numberStyle = .percent
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 1
        return formatter
    }
}

extension MeasurementFormatter {

    static var weightFormatter: MeasurementFormatter {
        let formatter = MeasurementFormatter()
        formatter.locale = Locale.current
        formatter.unitOptions = .naturalScale
        formatter.numberFormatter.maximumFractionDigits = 0
        return formatter
    }

    static var heightFormatter: MeasurementFormatter {
        let formatter = MeasurementFormatter()
        formatter.locale = Locale.current
        formatter.unitOptions = .providedUnit
        formatter.numberFormatter.maximumFractionDigits = 1
        return formatter
    }

    static var volumeFormatter: MeasurementFormatter {
        let formatter = MeasurementFormatter()
        formatter.locale = Locale.current
        formatter.unitOptions = .providedUnit
        formatter.numberFormatter.maximumFractionDigits = 0
        return formatter
    }
}

extension Date {

    var fullDateString: String {
        DateFormatter.fullDateFormatter.string(from: self)
    }

    var shortDateString: String {
        DateFormatter.shortDateFormatter.string(from: self)
    }

    var dateTimeString: String {
        DateFormatter.dateTimeFormatter.string(from: self)
    }

    var timeString: String {
        DateFormatter.timeFormatter.string(from: self)
    }

    var monthDayString: String {
        DateFormatter.monthDayFormatter.string(from: self)
    }

    var monthYearString: String {
        DateFormatter.monthYearFormatter.string(from: self)
    }

    func relativeString(to date: Date = Date()) -> String {
        RelativeDateTimeFormatter.relativeFormatter.localizedString(for: self, relativeTo: date)
    }

    func shortRelativeString(to date: Date = Date()) -> String {
        RelativeDateTimeFormatter.shortRelativeFormatter.localizedString(for: self, relativeTo: date)
    }

    func abbreviatedRelativeString(to date: Date = Date()) -> String {
        RelativeDateTimeFormatter.abbreviatedRelativeFormatter.localizedString(for: self, relativeTo: date)
    }
}

extension TimeInterval {

    var durationString: String {
        let hours = Int(self) / 3600
        let minutes = (Int(self) % 3600) / 60

        if hours > 0 {
            if minutes > 0 {
                return String(localized: "duration_hours_minutes", defaultValue: "\(hours)ч \(minutes)м")
            } else {
                return String(localized: "duration_hours", defaultValue: "\(hours)ч")
            }
        } else if minutes > 0 {
            return String(localized: "duration_minutes", defaultValue: "\(minutes)м")
        } else {
            let seconds = Int(self)
            return String(localized: "duration_seconds", defaultValue: "\(seconds)с")
        }
    }

    var fullDurationString: String {
        let hours = Int(self) / 3600
        let minutes = (Int(self) % 3600) / 60

        var components: [String] = []

        if hours > 0 {
            components.append(String(localized: "hours_count", defaultValue: "\(hours) hours"))
        }
        if minutes > 0 {
            components.append(String(localized: "minutes_count", defaultValue: "\(minutes) minutes"))
        }
        if components.isEmpty {
            let seconds = Int(self)
            components.append(String(localized: "seconds_count", defaultValue: "\(seconds) seconds"))
        }

        return components.joined(separator: " ")
    }
}

extension Locale {

    var isRussian: Bool {
        languageCode == "ru"
    }

    var isEnglish: Bool {
        languageCode == "en"
    }

    var safeLanguageCode: String {
        languageCode ?? "en"
    }

    var localizedName: String {
        localizedString(forIdentifier: identifier) ?? identifier
    }
}

extension Int {

    func localizedCount(key: String, defaultValue: String = "") -> String {
        String(localized: String.LocalizationValue(stringLiteral: key))
    }
}

extension String {

    func localized(with arguments: CVarArg...) -> String {
        String(format: NSLocalizedString(self, comment: ""), arguments: arguments)
    }

    func localized(comment: String = "") -> String {
        NSLocalizedString(self, comment: comment)
    }
}
