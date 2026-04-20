import Foundation
import AppIntents
import CoreData
import SwiftUI

@available(iOS 16.0, *)
enum DiaperTypeEntity: String, AppEnum {
    case wet = "wet"
    case dirty = "dirty"
    case both = "both"
    case clean = "clean"

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Тип подгузника"

    static var caseDisplayRepresentations: [DiaperTypeEntity: DisplayRepresentation] = [
        .wet: DisplayRepresentation(
            title: "Мокрый",
            subtitle: "Только мокрый"
        ),
        .dirty: DisplayRepresentation(
            title: "Грязный",
            subtitle: "Только грязный"
        ),
        .both: DisplayRepresentation(
            title: "Оба",
            subtitle: "Мокрый и грязный"
        ),
        .clean: DisplayRepresentation(
            title: "Чистый",
            subtitle: "Профилактическая смена"
        )
    ]
}

@available(iOS 16.0, *)
struct LogDiaperIntent: AppIntent, BabyCareIntent {

    static var title: LocalizedStringResource = "Записать смену подгузника"

    static var description = IntentDescription("Записать событие смены подгузника с указанием типа")

    @Parameter(
        title: "Тип подгузника",
        description: "Состояние подгузника при смене"
    )
    var diaperType: DiaperTypeEntity

    @Parameter(
        title: "Время смены",
        description: "Когда был поменян подгузник"
    )
    var timestamp: Date?

    @Parameter(title: "Заметки")
    var notes: String?

    static var parameterSummary: some ParameterSummary {
        Summary("Записать смену подгузника — \(\.$diaperType)") {
            \.$timestamp
            \.$notes
        }
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {

        let context = PersistenceController.shared.container.viewContext
        let repository = DiaperEventRepository(context: context)
        let childRepository = ChildProfileRepository(context: context)

        guard let child = childRepository.fetchAllChildren().first else {
            throw DiaperIntentError.noChildProfile
        }

        let changeTime = timestamp ?? Date()

        let diaperTypeString = convertDiaperType(diaperType)

        let event = try await repository.createDiaperEvent(
            childId: child.id ?? UUID(),
            timestamp: changeTime,
            diaperType: diaperTypeString,
            notes: notes
        )

        let responseMessage = buildResponseMessage(
            diaperType: diaperTypeString,
            timestamp: changeTime,
            childName: child.name ?? "малыша"
        )

        let snippet = DiaperSnippetView(
            diaperType: diaperTypeString,
            timestamp: event.timestamp ?? Date()
        )

        return .result(
            dialog: IntentDialog(stringLiteral: responseMessage),
            view: snippet
        )
    }

    private func convertDiaperType(_ type: DiaperTypeEntity) -> String {
        switch type {
        case .wet:
            return "Мокрый"
        case .dirty:
            return "Грязный"
        case .both:
            return "Оба"
        case .clean:
            return "Чистый"
        }
    }

    private func buildResponseMessage(
        diaperType: String,
        timestamp: Date,
        childName: String
    ) -> String {
        let timeFormatter = DateFormatter()
        timeFormatter.timeStyle = .short

        let typeDescription: String
        switch diaperType {
        case "Мокрый":
            typeDescription = "мокрый подгузник"
        case "Грязный":
            typeDescription = "грязный подгузник"
        case "Оба":
            typeDescription = "мокрый и грязный подгузник"
        case "Чистый":
            typeDescription = "чистый подгузник"
        default:
            typeDescription = "подгузник"
        }

        return "Записал смену для \(childName) в \(timeFormatter.string(from: timestamp)). Был \(typeDescription)."
    }
}

@available(iOS 16.0, *)
enum DiaperIntentError: Error, CustomLocalizedStringResourceConvertible {
    case noChildProfile
    case saveFailed

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .noChildProfile:
            return "Не найден профиль ребенка. Пожалуйста, создайте профиль в приложении."
        case .saveFailed:
            return "Не удалось сохранить запись о смене подгузника. Попробуйте еще раз."
        }
    }
}

@available(iOS 16.0, *)
struct DiaperSnippetView: View {
    let diaperType: String
    let timestamp: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "circle.grid.cross.fill")
                    .foregroundColor(.orange)
                    .font(.title2)

                Text("Подгузник поменян")
                    .font(.headline)
            }

            Divider()

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Тип:")
                        .foregroundColor(.secondary)
                    Text(diaperType)
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
