import Foundation
import AppIntents
import CoreData
import SwiftUI

@available(iOS 16.0, *)
enum SleepQualityEntity: String, AppEnum {
    case good = "good"
    case fair = "fair"
    case poor = "poor"

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Качество сна"

    static var caseDisplayRepresentations: [SleepQualityEntity: DisplayRepresentation] = [
        .good: DisplayRepresentation(
            title: "Хорошо",
            subtitle: "Малыш спал спокойно"
        ),
        .fair: DisplayRepresentation(
            title: "Средне",
            subtitle: "Малыш просыпался несколько раз"
        ),
        .poor: DisplayRepresentation(
            title: "Плохо",
            subtitle: "Малыш спал беспокойно"
        )
    ]
}

@available(iOS 16.0, *)
struct LogSleepIntent: AppIntent, BabyCareIntent {

    static var title: LocalizedStringResource = "Записать сон"

    static var description = IntentDescription("Записать событие сна ребенка с указанием времени начала, окончания и качества")

    @Parameter(
        title: "Время начала",
        description: "Когда малыш начал спать",
        requestValueDialog: IntentDialog("Когда малыш начал спать?")
    )
    var startTime: Date?

    @Parameter(
        title: "Время окончания",
        description: "Когда малыш проснулся (если уже проснулся)",
        requestValueDialog: IntentDialog("Когда малыш проснулся?")
    )
    var endTime: Date?

    @Parameter(
        title: "Длительность",
        description: "Длительность сна в минутах",
        controlStyle: .field,
        inclusiveRange: (1, 720),
        requestValueDialog: IntentDialog("Сколько минут длился сон?")
    )
    var durationMinutes: Int?

    @Parameter(
        title: "Качество сна",
        description: "Как спал малыш"
    )
    var quality: SleepQualityEntity?

    @Parameter(title: "Заметки")
    var notes: String?

    static var parameterSummary: some ParameterSummary {
        Summary("Записать сон") {
            \.$startTime
            \.$endTime
            \.$durationMinutes
            \.$quality
            \.$notes
        }
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {

        let context = PersistenceController.shared.container.viewContext
        let repository = SleepEventRepository(context: context)
        let childRepository = ChildProfileRepository(context: context)

        guard let child = childRepository.fetchAllChildren().first else {
            throw SleepIntentError.noChildProfile
        }

        let calculatedTimes = calculateSleepTimes(
            startTime: startTime,
            endTime: endTime,
            durationMinutes: durationMinutes
        )

        let event = try await repository.createSleepEvent(
            childId: child.id ?? UUID(),
            startTime: calculatedTimes.start,
            endTime: calculatedTimes.end,
            quality: quality.map { convertQuality($0) },
            location: nil,
            notes: notes
        )

        let responseMessage = buildResponseMessage(
            startTime: calculatedTimes.start,
            endTime: calculatedTimes.end,
            quality: quality,
            childName: child.name ?? "малыша"
        )

        let snippet = SleepSnippetView(
            startTime: calculatedTimes.start,
            endTime: calculatedTimes.end,
            quality: quality.map { convertQuality($0) },
            duration: event.duration
        )

        return .result(
            dialog: IntentDialog(stringLiteral: responseMessage),
            view: snippet
        )
    }

    private func calculateSleepTimes(
        startTime: Date?,
        endTime: Date?,
        durationMinutes: Int?
    ) -> (start: Date, end: Date?) {

        if let start = startTime, let end = endTime {
            return (start, end)
        }

        if let start = startTime {
            if let duration = durationMinutes {
                let end = start.addingTimeInterval(Double(duration * 60))
                return (start, end)
            }
            return (start, nil)
        }

        if let end = endTime, let duration = durationMinutes {
            let start = end.addingTimeInterval(-Double(duration * 60))
            return (start, end)
        }

        if let duration = durationMinutes {
            let end = Date()
            let start = end.addingTimeInterval(-Double(duration * 60))
            return (start, end)
        }

        return (Date(), nil)
    }

    private func convertQuality(_ quality: SleepQualityEntity) -> String {
        switch quality {
        case .good:
            return "Хорошо"
        case .fair:
            return "Средне"
        case .poor:
            return "Плохо"
        }
    }

    private func buildResponseMessage(
        startTime: Date,
        endTime: Date?,
        quality: SleepQualityEntity?,
        childName: String
    ) -> String {
        var message = "Записал сон для \(childName). "

        let timeFormatter = DateFormatter()
        timeFormatter.timeStyle = .short

        if let endTime = endTime {

            let duration = Int(endTime.timeIntervalSince(startTime) / 60)
            message += "Спал с \(timeFormatter.string(from: startTime)) до \(timeFormatter.string(from: endTime))"
            message += " (\(formatDuration(duration)))."
        } else {

            message += "Начал спать в \(timeFormatter.string(from: startTime))."
        }

        if let quality = quality {
            message += " Качество сна: \(convertQuality(quality).lowercased())."
        }

        return message
    }

    private func formatDuration(_ minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60

        if hours > 0 && mins > 0 {
            return "\(hours) ч \(mins) мин"
        } else if hours > 0 {
            return "\(hours) ч"
        } else {
            return "\(mins) мин"
        }
    }
}

@available(iOS 16.0, *)
enum SleepIntentError: Error, CustomLocalizedStringResourceConvertible {
    case noChildProfile
    case saveFailed
    case invalidTimeRange

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .noChildProfile:
            return "Не найден профиль ребенка. Пожалуйста, создайте профиль в приложении."
        case .saveFailed:
            return "Не удалось сохранить запись о сне. Попробуйте еще раз."
        case .invalidTimeRange:
            return "Неверный временной диапазон. Время окончания должно быть позже времени начала."
        }
    }
}

@available(iOS 16.0, *)
struct SleepSnippetView: View {
    let startTime: Date
    let endTime: Date?
    let quality: String?
    let duration: Int32

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "moon.stars.fill")
                    .foregroundColor(.purple)
                    .font(.title2)

                Text(endTime == nil ? "Сон начат" : "Сон записан")
                    .font(.headline)
            }

            Divider()

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Начало:")
                        .foregroundColor(.secondary)
                    Text(startTime, style: .time)
                }

                if let endTime = endTime {
                    HStack {
                        Text("Окончание:")
                            .foregroundColor(.secondary)
                        Text(endTime, style: .time)
                    }

                    HStack {
                        Text("Длительность:")
                            .foregroundColor(.secondary)
                        Text(formatDuration(Int(duration)))
                    }
                }

                if let quality = quality {
                    HStack {
                        Text("Качество:")
                            .foregroundColor(.secondary)
                        Text(quality)
                    }
                }
            }
            .font(.subheadline)
        }
        .padding()
    }

    private func formatDuration(_ minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60

        if hours > 0 && mins > 0 {
            return "\(hours) ч \(mins) мин"
        } else if hours > 0 {
            return "\(hours) ч"
        } else {
            return "\(mins) мин"
        }
    }
}
