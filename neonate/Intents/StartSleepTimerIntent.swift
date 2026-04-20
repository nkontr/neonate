import Foundation
import AppIntents
import CoreData
import SwiftUI

@available(iOS 16.0, *)
struct StartSleepTimerIntent: AppIntent, BabyCareIntent {

    static var title: LocalizedStringResource = "Начать отслеживание сна"

    static var description = IntentDescription("Запустить таймер для отслеживания сна ребенка")

    @Parameter(
        title: "Время начала",
        description: "Когда малыш начал спать"
    )
    var startTime: Date?

    @Parameter(title: "Заметки")
    var notes: String?

    static var parameterSummary: some ParameterSummary {
        Summary("Начать отслеживание сна") {
            \.$startTime
            \.$notes
        }
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {

        let context = PersistenceController.shared.container.viewContext
        let repository = SleepEventRepository(context: context)
        let childRepository = ChildProfileRepository(context: context)

        guard let child = childRepository.fetchAllChildren().first else {
            throw SleepTimerIntentError.noChildProfile
        }

        if let activeSleep = repository.fetchActiveSleep(for: child.id ?? UUID()) {

            let existingDuration = Int(Date().timeIntervalSince(activeSleep.startTime ?? Date()) / 60)

            let snippet = ActiveSleepSnippetView(
                startTime: activeSleep.startTime ?? Date(),
                currentDuration: existingDuration
            )

            return .result(
                dialog: IntentDialog("Сон уже отслеживается. Малыш спит уже \(formatDuration(existingDuration))."),
                view: snippet
            )
        }

        let sleepStartTime = startTime ?? Date()

        let event = try await repository.createSleepEvent(
            childId: child.id ?? UUID(),
            startTime: sleepStartTime,
            endTime: nil,
            quality: nil,
            location: nil,
            notes: notes
        )

        let timeFormatter = DateFormatter()
        timeFormatter.timeStyle = .short
        let responseMessage = "Начал отслеживать сон для \(child.name ?? "малыша") с \(timeFormatter.string(from: sleepStartTime))."

        let snippet = SleepTimerSnippetView(
            startTime: sleepStartTime,
            childName: child.name ?? "Малыш"
        )

        return .result(
            dialog: IntentDialog(stringLiteral: responseMessage),
            view: snippet
        )
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
enum SleepTimerIntentError: Error, CustomLocalizedStringResourceConvertible {
    case noChildProfile
    case alreadyTracking
    case saveFailed

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .noChildProfile:
            return "Не найден профиль ребенка. Пожалуйста, создайте профиль в приложении."
        case .alreadyTracking:
            return "Сон уже отслеживается. Сначала завершите текущую сессию."
        case .saveFailed:
            return "Не удалось начать отслеживание сна. Попробуйте еще раз."
        }
    }
}

@available(iOS 16.0, *)
struct SleepTimerSnippetView: View {
    let startTime: Date
    let childName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "moon.stars.fill")
                    .foregroundColor(.purple)
                    .font(.title2)

                Text("Таймер сна запущен")
                    .font(.headline)
            }

            Divider()

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Ребенок:")
                        .foregroundColor(.secondary)
                    Text(childName)
                }

                HStack {
                    Text("Начало:")
                        .foregroundColor(.secondary)
                    Text(startTime, style: .time)
                }

                HStack {
                    Image(systemName: "clock.fill")
                        .foregroundColor(.purple)
                        .font(.caption)
                    Text("Отслеживание активно")
                        .foregroundColor(.purple)
                        .font(.caption)
                        .fontWeight(.medium)
                }
            }
            .font(.subheadline)
        }
        .padding()
    }
}

@available(iOS 16.0, *)
struct ActiveSleepSnippetView: View {
    let startTime: Date
    let currentDuration: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "moon.stars.fill")
                    .foregroundColor(.purple)
                    .font(.title2)

                Text("Сон уже отслеживается")
                    .font(.headline)
            }

            Divider()

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Начало:")
                        .foregroundColor(.secondary)
                    Text(startTime, style: .time)
                }

                HStack {
                    Text("Длительность:")
                        .foregroundColor(.secondary)
                    Text(formatDuration(currentDuration))
                }

                HStack {
                    Image(systemName: "clock.fill")
                        .foregroundColor(.purple)
                        .font(.caption)
                    Text("Таймер активен")
                        .foregroundColor(.purple)
                        .font(.caption)
                        .fontWeight(.medium)
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
