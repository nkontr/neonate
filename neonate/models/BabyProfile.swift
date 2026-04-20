import Foundation

struct BabyProfile: Identifiable, Codable {
    var id: UUID
    var name: String
    var birthDate: Date
    var gender: Gender
    var photoData: Data?
    var birthWeight: Double?
    var birthHeight: Double?
    var bloodType: String?
    var notes: String?

    init(
        id: UUID = UUID(),
        name: String,
        birthDate: Date,
        gender: Gender,
        photoData: Data? = nil,
        birthWeight: Double? = nil,
        birthHeight: Double? = nil,
        bloodType: String? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.name = name
        self.birthDate = birthDate
        self.gender = gender
        self.photoData = photoData
        self.birthWeight = birthWeight
        self.birthHeight = birthHeight
        self.bloodType = bloodType
        self.notes = notes
    }

    var ageInYears: Int {
        return birthDate.ageInYears
    }

    var ageInMonths: Int {
        return birthDate.ageInMonths
    }

    var ageInDays: Int {
        return birthDate.ageInDays
    }

    var formattedAge: String {
        let years = ageInYears
        let months = ageInMonths % 12
        let days = ageInDays % 30

        if years > 0 {
            return "\(years) г. \(months) мес."
        } else if months > 0 {
            return "\(months) мес. \(days) дн."
        } else {
            return "\(days) дн."
        }
    }

    var formattedBirthDate: String {
        return birthDate.formatted(dateStyle: .long, timeStyle: .none)
    }
}

enum Gender: String, CaseIterable, Codable {
    case male = "Мальчик"
    case female = "Девочка"

    var icon: String {
        switch self {
        case .male:
            return "figure.child"
        case .female:
            return "figure.child"
        }
    }

    var colorName: String {
        switch self {
        case .male:
            return "blue"
        case .female:
            return "pink"
        }
    }
}
