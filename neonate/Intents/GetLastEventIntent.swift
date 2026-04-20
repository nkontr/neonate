import Foundation
import AppIntents
import CoreData
import SwiftUI

@available(iOS 16.0, *)
enum EventTypeEntity: String, AppEnum {
    case feeding = "feeding"
    case sleep = "sleep"
    case diaper = "diaper"
    case any = "any"

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Тип события"

    static var caseDisplayRepresentations: [EventTypeEntity: DisplayRepresentation] = [
        .feeding: DisplayRepresentation(
            title: "Кормление",
            subtitle: "Последнее кормление"
        ),
        .sleep: DisplayRepresentation(
            title: "Сон",
            subtitle: "Последний сон"
        ),
        .diaper: DisplayRepresentation(
            title: "Подгузник",
            subtitle: "Последняя смена"
        ),
        .any: DisplayRepresentation(
            title: "Любое",
            subtitle: "Последнее событие"
        )
    ]
}

@available(iOS 16.0, *)
struct GetLastEventIntent: AppIntent, BabyCareIntent {

    static var title: LocalizedStringResource = "Когда было последнее событие"

    static var description = IntentDescription("Узнать информацию о последнем кормлении, сне или смене подгузника")

    @Parameter(
        title: "Тип события",
        description: "Какое событие вас интересует",
        default: .any
    )
    var eventType: EventTypeEntity

    static var parameterSummary: some ParameterSummary {
        Summary("Когда было последнее \(\.$eventType)")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {

        let context = PersistenceController.shared.container.viewContext
        let childRepository = ChildProfileRepository(context: context)

        guard let child = childRepository.fetchAllChildren().first else {
            throw EventQueryIntentError.noChildProfile
        }

        let childId = child.id ?? UUID()

        let eventInfo: EventInfo
        switch eventType {
        case .feeding:
            eventInfo = try getLastFeedingInfo(childId: childId, context: context)
        case .sleep:
            eventInfo = try getLastSleepInfo(childId: childId, context: context)
        case .diaper:
            eventInfo = try getLastDiaperInfo(childId: childId, context: context)
        case .any:
            eventInfo = try getLastAnyEventInfo(childId: childId, context: context)
        }

        let responseMessage = buildResponseMessage(
            eventInfo: eventInfo,
            childName: child.name ?? "малыша"
        )

        let snippet = EventInfoSnippetView(eventInfo: eventInfo)

        return .result(
            dialog: IntentDialog(stringLiteral: responseMessage),
            view: snippet
        )
    }

    private func getLastFeedingInfo(childId: UUID, context: NSManagedObjectContext) throws -> EventInfo {
        let repository = FeedingEventRepository(context: context)

        guard let lastEvent = repository.fetchLastFeedingEvent(for: childId) else {
            throw EventQueryIntentError.noEvents
        }

        let details = buildFeedingDetails(event: lastEvent)
        let timeSince = repository.getTimeSinceLastFeeding(for: childId)

        return EventInfo(
            type: "Кормление",
            timestamp: lastEvent.timestamp ?? Date(),
            details: details,
            minutesSince: timeSince
        )
    }

    private func getLastSleepInfo(childId: UUID, context: NSManagedObjectContext) throws -> EventInfo {
        let repository = SleepEventRepository(context: context)

        guard let lastEvent = repository.fetchSleepEvents(for: childId, ascending: false).first else {
            throw EventQueryIntentError.noEvents
        }

        let details = buildSleepDetails(event: lastEvent)
        let timeSince = repository.getTimeSinceLastSleep(for: childId)

        return EventInfo(
            type: "Сон",
            timestamp: lastEvent.startTime ?? Date(),
            details: details,
            minutesSince: timeSince
        )
    }

    private func getLastDiaperInfo(childId: UUID, context: NSManagedObjectContext) throws -> EventInfo {
        let repository = DiaperEventRepository(context: context)

        guard let lastEvent = repository.fetchLastDiaperEvent(for: childId) else {
            throw EventQueryIntentError.noEvents
        }

        let details = "Тип: \(lastEvent.diaperType ?? "неизвестно")"
        let timeSince = repository.getTimeSinceLastDiaperChange(for: childId)

        return EventInfo(
            type: "Смена подгузника",
            timestamp: lastEvent.timestamp ?? Date(),
            details: details,
            minutesSince: timeSince
        )
    }

    private func getLastAnyEventInfo(childId: UUID, context: NSManagedObjectContext) throws -> EventInfo {

        let feedingRepo = FeedingEventRepository(context: context)
        let sleepRepo = SleepEventRepository(context: context)
        let diaperRepo = DiaperEventRepository(context: context)

        let lastFeeding = feedingRepo.fetchLastFeedingEvent(for: childId)
        let lastSleep = sleepRepo.fetchSleepEvents(for: childId, ascending: false).first
        let lastDiaper = diaperRepo.fetchLastDiaperEvent(for: childId)

        var latestEvent: (type: String, timestamp: Date, details: String, minutesSince: Int?)?

        if let feeding = lastFeeding {
            latestEvent = ("Кормление", feeding.timestamp ?? Date(), buildFeedingDetails(event: feeding), feedingRepo.getTimeSinceLastFeeding(for: childId))
        }

        if let sleep = lastSleep, latestEvent == nil || (sleep.startTime ?? Date()) > latestEvent!.timestamp {
            latestEvent = ("Сон", sleep.startTime ?? Date(), buildSleepDetails(event: sleep), sleepRepo.getTimeSinceLastSleep(for: childId))
        }

        if let diaper = lastDiaper, latestEvent == nil || (diaper.timestamp ?? Date()) > latestEvent!.timestamp {
            latestEvent = ("Смена подгузника", diaper.timestamp ?? Date(), "Тип: \(diaper.diaperType ?? "неизвестно")", diaperRepo.getTimeSinceLastDiaperChange(for: childId))
        }

        guard let event = latestEvent else {
            throw EventQueryIntentError.noEvents
        }

        return EventInfo(
            type: event.type,
            timestamp: event.timestamp,
            details: event.details,
            minutesSince: event.minutesSince
        )
    }

    private func buildFeedingDetails(event: FeedingEvent) -> String {
        var details = "Тип: \(event.feedingType ?? "неизвестно")"

        if event.feedingType == "Грудное", event.duration > 0 {
            details += ", \(event.duration) мин"
            if let breast = event.breast {
                details += " (\(breast))"
            }
        } else if event.volume > 0 {
            details += ", \(Int(event.volume)) мл"
        }

        return details
    }

    private func buildSleepDetails(event: SleepEvent) -> String {
        if event.endTime == nil {
            return "Сейчас спит (начал в \(formatTime(event.startTime ?? Date())))"
        } else {
            let duration = Int(event.duration)
            return "Длительность: \(formatDuration(duration))"
        }
    }

    private func buildResponseMessage(eventInfo: EventInfo, childName: String) -> String {
        let timeFormatter = DateFormatter()
        timeFormatter.timeStyle = .short

        var message = "Последнее событие для \(childName): "
        message += "\(eventInfo.type.lowercased()) в \(timeFormatter.string(from: eventInfo.timestamp))"

        if let minutesSince = eventInfo.minutesSince {
            message += " (\(formatTimeSince(minutesSince)) назад)"
        }

        message += ". \(eventInfo.details)"

        return message
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
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

    private func formatTimeSince(_ minutes: Int) -> String {
        if minutes < 60 {
            return "\(minutes) мин"
        } else if minutes < 1440 {
            let hours = minutes / 60
            return "\(hours) ч"
        } else {
            let days = minutes / 1440
            return "\(days) д"
        }
    }
}

struct EventInfo {
    let type: String
    let timestamp: Date
    let details: String
    let minutesSince: Int?
}

@available(iOS 16.0, *)
enum EventQueryIntentError: Error, CustomLocalizedStringResourceConvertible {
    case noChildProfile
    case noEvents

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .noChildProfile:
            return "Не найден профиль ребенка. Пожалуйста, создайте профиль в приложении."
        case .noEvents:
            return "Пока нет записанных событий. Добавьте первое событие в приложении."
        }
    }
}

@available(iOS 16.0, *)
struct EventInfoSnippetView: View {
    let eventInfo: EventInfo

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: iconForEventType(eventInfo.type))
                    .foregroundColor(colorForEventType(eventInfo.type))
                    .font(.title2)

                Text(eventInfo.type)
                    .font(.headline)
            }

            Divider()

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Время:")
                        .foregroundColor(.secondary)
                    Text(eventInfo.timestamp, style: .time)
                }

                if let minutesSince = eventInfo.minutesSince {
                    HStack {
                        Text("Прошло:")
                            .foregroundColor(.secondary)
                        Text(formatTimeSince(minutesSince))
                    }
                }

                Text(eventInfo.details)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 2)
            }
            .font(.subheadline)
        }
        .padding()
    }

    private func iconForEventType(_ type: String) -> String {
        switch type {
        case "Кормление":
            return "fork.knife"
        case "Сон":
            return "moon.stars.fill"
        case "Смена подгузника":
            return "circle.grid.cross.fill"
        default:
            return "list.bullet"
        }
    }

    private func colorForEventType(_ type: String) -> Color {
        switch type {
        case "Кормление":
            return .blue
        case "Сон":
            return .purple
        case "Смена подгузника":
            return .orange
        default:
            return .gray
        }
    }

    private func formatTimeSince(_ minutes: Int) -> String {
        if minutes < 60 {
            return "\(minutes) мин назад"
        } else if minutes < 1440 {
            let hours = minutes / 60
            return "\(hours) ч назад"
        } else {
            let days = minutes / 1440
            return "\(days) д назад"
        }
    }
}
