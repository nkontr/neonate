import Foundation
import AppIntents
import CoreData
import SwiftUI

@available(iOS 16.0, *)
enum FeedingTypeEntity: String, AppEnum {
    case breast = "breast"
    case bottle = "bottle"
    case solid = "solid"

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Тип кормления"

    static var caseDisplayRepresentations: [FeedingTypeEntity: DisplayRepresentation] = [
        .breast: DisplayRepresentation(
            title: "Грудное",
            subtitle: "Кормление грудью"
        ),
        .bottle: DisplayRepresentation(
            title: "Бутылочка",
            subtitle: "Кормление из бутылочки"
        ),
        .solid: DisplayRepresentation(
            title: "Прикорм",
            subtitle: "Твердая пища"
        )
    ]
}

@available(iOS 16.0, *)
enum BreastSideEntity: String, AppEnum {
    case left = "left"
    case right = "right"
    case both = "both"

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Грудь"

    static var caseDisplayRepresentations: [BreastSideEntity: DisplayRepresentation] = [
        .left: "Левая",
        .right: "Правая",
        .both: "Обе"
    ]
}

@available(iOS 16.0, *)
struct LogFeedingIntent: AppIntent, BabyCareIntent {

    static var title: LocalizedStringResource = "Записать кормление"

    static var description = IntentDescription("Записать событие кормления ребенка с указанием типа, длительности и объема")

    @Parameter(title: "Тип кормления")
    var feedingType: FeedingTypeEntity

    @Parameter(
        title: "Длительность",
        description: "Длительность кормления в минутах (для грудного вскармливания)",
        controlStyle: .field,
        inclusiveRange: (1, 120),
        requestValueDialog: IntentDialog("Сколько минут длилось кормление?")
    )
    var duration: Int?

    @Parameter(
        title: "Объем",
        description: "Объем кормления в миллилитрах (для бутылочки и прикорма)",
        controlStyle: .field,
        inclusiveRange: (1, 500),
        requestValueDialog: IntentDialog("Сколько миллилитров выпил малыш?")
    )
    var volume: Int?

    @Parameter(
        title: "Грудь",
        description: "Какая грудь использовалась для кормления"
    )
    var breast: BreastSideEntity?

    @Parameter(title: "Заметки")
    var notes: String?

    static var parameterSummary: some ParameterSummary {
        Summary("Записать \(\.$feedingType)") {
            \.$duration
            \.$volume
            \.$breast
            \.$notes
        }
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {

        let context = PersistenceController.shared.container.viewContext
        let repository = FeedingEventRepository(context: context)
        let childRepository = ChildProfileRepository(context: context)

        guard let child = childRepository.fetchAllChildren().first else {
            throw FeedingIntentError.noChildProfile
        }

        let feedingTypeString = convertFeedingType(feedingType)

        let event = try await repository.createFeedingEvent(
            childId: child.id ?? UUID(),
            timestamp: Date(),
            feedingType: feedingTypeString,
            duration: duration.map { Int32($0) },
            volume: volume.map { Double($0) },
            breast: breast.map { convertBreastSide($0) },
            notes: notes
        )

        let responseMessage = buildResponseMessage(
            feedingType: feedingTypeString,
            duration: duration,
            volume: volume,
            childName: child.name ?? "малыша"
        )

        let snippet = FeedingSnippetView(
            feedingType: feedingTypeString,
            duration: duration,
            volume: volume,
            timestamp: event.timestamp ?? Date()
        )

        return .result(
            dialog: IntentDialog(stringLiteral: responseMessage),
            view: snippet
        )
    }

    private func convertFeedingType(_ type: FeedingTypeEntity) -> String {
        switch type {
        case .breast:
            return "Грудное"
        case .bottle:
            return "Бутылочка"
        case .solid:
            return "Прикорм"
        }
    }

    private func convertBreastSide(_ side: BreastSideEntity) -> String {
        switch side {
        case .left:
            return "Левая"
        case .right:
            return "Правая"
        case .both:
            return "Обе"
        }
    }

    private func buildResponseMessage(
        feedingType: String,
        duration: Int?,
        volume: Int?,
        childName: String
    ) -> String {
        var message = "Записал кормление для \(childName). "

        switch feedingType {
        case "Грудное":
            if let duration = duration {
                message += "Грудное вскармливание \(duration) минут."
            } else {
                message += "Грудное вскармливание."
            }
        case "Бутылочка":
            if let volume = volume {
                message += "Из бутылочки \(volume) мл."
            } else {
                message += "Из бутылочки."
            }
        case "Прикорм":
            if let volume = volume {
                message += "Прикорм \(volume) грамм."
            } else {
                message += "Прикорм."
            }
        default:
            message += feedingType
        }

        return message
    }
}

@available(iOS 16.0, *)
enum FeedingIntentError: Error, CustomLocalizedStringResourceConvertible {
    case noChildProfile
    case saveFailed

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .noChildProfile:
            return "Не найден профиль ребенка. Пожалуйста, создайте профиль в приложении."
        case .saveFailed:
            return "Не удалось сохранить запись о кормлении. Попробуйте еще раз."
        }
    }
}

@available(iOS 16.0, *)
struct FeedingSnippetView: View {
    let feedingType: String
    let duration: Int?
    let volume: Int?
    let timestamp: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "fork.knife")
                    .foregroundColor(.blue)
                    .font(.title2)

                Text("Кормление записано")
                    .font(.headline)
            }

            Divider()

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Тип:")
                        .foregroundColor(.secondary)
                    Text(feedingType)
                }

                if let duration = duration {
                    HStack {
                        Text("Длительность:")
                            .foregroundColor(.secondary)
                        Text("\(duration) мин")
                    }
                }

                if let volume = volume {
                    HStack {
                        Text("Объем:")
                            .foregroundColor(.secondary)
                        Text("\(volume) мл")
                    }
                }

                HStack {
                    Text("Время:")
                        .foregroundColor(.secondary)
                    Text(timestamp, style: .time)
                }
            }
            .font(.subheadline)
        }
        .padding()
    }
}
