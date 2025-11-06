import Foundation

enum BabyCareEventType: String, CaseIterable, Codable {
    case feeding = "Кормление"
    case sleep = "Сон"
    case diaper = "Подгузник"
    case bath = "Купание"
    case medication = "Лекарство"
    case temperature = "Температура"
    case weight = "Вес"
    case height = "Рост"
    case note = "Заметка"

    var icon: String {
        switch self {
        case .feeding:
            return "fork.knife"
        case .sleep:
            return "moon.stars.fill"
        case .diaper:
            return "circle.grid.cross.fill"
        case .bath:
            return "shower.fill"
        case .medication:
            return "pills.fill"
        case .temperature:
            return "thermometer"
        case .weight:
            return "scalemass.fill"
        case .height:
            return "ruler.fill"
        case .note:
            return "note.text"
        }
    }

    var colorName: String {
        switch self {
        case .feeding:
            return "blue"
        case .sleep:
            return "purple"
        case .diaper:
            return "orange"
        case .bath:
            return "cyan"
        case .medication:
            return "red"
        case .temperature:
            return "pink"
        case .weight:
            return "green"
        case .height:
            return "teal"
        case .note:
            return "gray"
        }
    }
}

struct BabyCareEventModel: Identifiable, Codable {
    var id: UUID
    var type: BabyCareEventType
    var timestamp: Date
    var notes: String?
    var value: String?
    var duration: TimeInterval?

    init(
        id: UUID = UUID(),
        type: BabyCareEventType,
        timestamp: Date = Date(),
        notes: String? = nil,
        value: String? = nil,
        duration: TimeInterval? = nil
    ) {
        self.id = id
        self.type = type
        self.timestamp = timestamp
        self.notes = notes
        self.value = value
        self.duration = duration
    }

    var displayTitle: String {
        return type.rawValue
    }

    var formattedTime: String {
        return timestamp.formatted(with: "HH:mm")
    }

    var formattedDate: String {
        return timestamp.formatted(dateStyle: .medium, timeStyle: .none)
    }

    var formattedDuration: String? {
        guard let duration = duration else { return nil }

        let hours = Int(duration) / 3600
        let minutes = Int(duration) / 60 % 60

        if hours > 0 {
            return "\(hours) ч \(minutes) мин"
        } else {
            return "\(minutes) мин"
        }
    }
}
