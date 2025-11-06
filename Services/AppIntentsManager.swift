import Foundation
import AppIntents

@available(iOS 16.0, *)
@MainActor
class AppIntentsManager {

    static let shared = AppIntentsManager()

    private init() {}

    func donateLogFeedingIntent(
        feedingType: String,
        duration: Int32?,
        volume: Double?,
        breast: String?
    ) {

        let feedingTypeEntity: FeedingTypeEntity
        switch feedingType {
        case "Грудное":
            feedingTypeEntity = .breast
        case "Бутылочка":
            feedingTypeEntity = .bottle
        case "Прикорм":
            feedingTypeEntity = .solid
        default:
            feedingTypeEntity = .breast
        }

        var breastEntity: BreastSideEntity?
        if let breast = breast {
            switch breast {
            case "Левая":
                breastEntity = .left
            case "Правая":
                breastEntity = .right
            case "Обе":
                breastEntity = .both
            default:
                breastEntity = nil
            }
        }

        let intent = LogFeedingIntent()
        intent.feedingType = feedingTypeEntity
        intent.duration = duration.map { Int($0) }
        intent.volume = volume.map { Int($0) }
        intent.breast = breastEntity

        Task {
            do {
                try await intent.donate()
                print("✅ Интент кормления задонатен: \(feedingType)")
            } catch {
                print("❌ Ошибка донации интента кормления: \(error)")
            }
        }
    }

    func donateLogSleepIntent(
        startTime: Date,
        endTime: Date?,
        quality: String?
    ) {

        var qualityEntity: SleepQualityEntity?
        if let quality = quality {
            switch quality {
            case "Хорошо":
                qualityEntity = .good
            case "Средне":
                qualityEntity = .fair
            case "Плохо":
                qualityEntity = .poor
            default:
                qualityEntity = nil
            }
        }

        var durationMinutes: Int?
        if let endTime = endTime {
            durationMinutes = Int(endTime.timeIntervalSince(startTime) / 60)
        }

        let intent = LogSleepIntent()
        intent.startTime = startTime
        intent.endTime = endTime
        intent.durationMinutes = durationMinutes
        intent.quality = qualityEntity

        Task {
            do {
                try await intent.donate()
                print("✅ Интент сна задонатен: \(startTime)")
            } catch {
                print("❌ Ошибка донации интента сна: \(error)")
            }
        }
    }

    func donateStartSleepTimerIntent() {
        let intent = StartSleepTimerIntent()

        Task {
            do {
                try await intent.donate()
                print("✅ Интент таймера сна задонатен")
            } catch {
                print("❌ Ошибка донации интента таймера сна: \(error)")
            }
        }
    }

    func donateLogDiaperIntent(
        diaperType: String,
        timestamp: Date = Date()
    ) {

        let diaperTypeEntity: DiaperTypeEntity
        switch diaperType {
        case "Мокрый":
            diaperTypeEntity = .wet
        case "Грязный":
            diaperTypeEntity = .dirty
        case "Оба":
            diaperTypeEntity = .both
        case "Чистый":
            diaperTypeEntity = .clean
        default:
            diaperTypeEntity = .wet
        }

        let intent = LogDiaperIntent()
        intent.diaperType = diaperTypeEntity
        intent.timestamp = timestamp

        Task {
            do {
                try await intent.donate()
                print("✅ Интент смены подгузника задонатен: \(diaperType)")
            } catch {
                print("❌ Ошибка донации интента смены подгузника: \(error)")
            }
        }
    }

    func donateGetLastEventIntent(eventType: String? = nil) {
        var eventTypeEntity: EventTypeEntity = .any

        if let eventType = eventType {
            switch eventType {
            case "Кормление":
                eventTypeEntity = .feeding
            case "Сон":
                eventTypeEntity = .sleep
            case "Подгузник":
                eventTypeEntity = .diaper
            default:
                eventTypeEntity = .any
            }
        }

        let intent = GetLastEventIntent()
        intent.eventType = eventTypeEntity

        Task {
            do {
                try await intent.donate()
                print("✅ Интент запроса последнего события задонатен")
            } catch {
                print("❌ Ошибка донации интента запроса: \(error)")
            }
        }
    }

    func updateShortcutSuggestions() {
        Task {
            do {

                print("✅ Suggestions обновлены")
            } catch {
                print("❌ Ошибка обновления suggestions: \(error)")
            }
        }
    }

    func deleteAllDonations() {
        Task {
            do {

                print("⚠️ Все донации удалены")
            } catch {
                print("❌ Ошибка удаления донаций: \(error)")
            }
        }
    }

    var isAppIntentsAvailable: Bool {
        if #available(iOS 16.0, *) {
            return true
        } else {
            return false
        }
    }
}

@available(iOS 16.0, *)
extension AppIntentsManager {

    func donateInitialIntents() {

        donateGetLastEventIntent(eventType: "Кормление")
        donateGetLastEventIntent(eventType: "Сон")
        donateGetLastEventIntent(eventType: "Подгузник")
        donateStartSleepTimerIntent()

        print("✅ Базовые интенты задонатены для обучения Siri")
    }

    func donateEventIntent(eventType: String, parameters: [String: Any]) {
        switch eventType {
        case "Кормление":
            donateLogFeedingIntent(
                feedingType: parameters["feedingType"] as? String ?? "Грудное",
                duration: parameters["duration"] as? Int32,
                volume: parameters["volume"] as? Double,
                breast: parameters["breast"] as? String
            )

        case "Сон":
            donateLogSleepIntent(
                startTime: parameters["startTime"] as? Date ?? Date(),
                endTime: parameters["endTime"] as? Date,
                quality: parameters["quality"] as? String
            )

        case "Подгузник":
            donateLogDiaperIntent(
                diaperType: parameters["diaperType"] as? String ?? "Мокрый",
                timestamp: parameters["timestamp"] as? Date ?? Date()
            )

        default:
            print("⚠️ Неизвестный тип события для донации: \(eventType)")
        }
    }
}
