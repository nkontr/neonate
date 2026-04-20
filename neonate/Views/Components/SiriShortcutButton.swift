import SwiftUI
import AppIntents

enum ShortcutType {
    case feeding
    case sleep
    case sleepTimer
    case diaper
    case lastEvent
}

struct SiriShortcutButton: View {

    let shortcutType: ShortcutType
    let title: String

    @State private var isAdded: Bool = false

    var body: some View {
        if #available(iOS 16.0, *) {
            Button(action: {
                addToSiri()
            }) {
                HStack(spacing: 12) {
                    Image(systemName: isAdded ? "checkmark.circle.fill" : "plus.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(isAdded ? .green : .white)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(isAdded ? "Добавлено в Siri" : "Добавить в Siri")
                            .font(.subheadline)
                            .fontWeight(.medium)

                        Text(title)
                            .font(.caption)
                            .opacity(0.8)
                    }

                    Spacer()

                    Image(systemName: "waveform")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding()
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.8, green: 0.2, blue: 0.9),
                            Color(red: 0.5, green: 0.3, blue: 1.0)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundColor(.white)
                .cornerRadius(12)
                .shadow(color: Color.purple.opacity(0.3), radius: 5, x: 0, y: 2)
            }
            .buttonStyle(.plain)
        }
    }

    @available(iOS 16.0, *)
    private func addToSiri() {

        Task {
            do {
                let intent = createIntent()
                try await intent.donate()

                withAnimation {
                    isAdded = true
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation {
                        isAdded = false
                    }
                }

                print("✅ Shortcut добавлен в Siri: \(shortcutType)")
            } catch {
                print("❌ Ошибка добавления в Siri: \(error)")
            }
        }
    }

    @available(iOS 16.0, *)
    private func createIntent() -> any AppIntent {
        switch shortcutType {
        case .feeding:
            let intent = LogFeedingIntent()
            intent.feedingType = .breast
            return intent

        case .sleep:
            let intent = LogSleepIntent()
            return intent

        case .sleepTimer:
            let intent = StartSleepTimerIntent()
            return intent

        case .diaper:
            let intent = LogDiaperIntent()
            intent.diaperType = .wet
            return intent

        case .lastEvent:
            let intent = GetLastEventIntent()
            intent.eventType = .any
            return intent
        }
    }
}

struct SiriShortcutButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
            SiriShortcutButton(
                shortcutType: .feeding,
                title: "Записать кормление"
            )

            SiriShortcutButton(
                shortcutType: .sleep,
                title: "Записать сон"
            )

            SiriShortcutButton(
                shortcutType: .sleepTimer,
                title: "Начать таймер сна"
            )

            SiriShortcutButton(
                shortcutType: .diaper,
                title: "Записать смену подгузника"
            )

            SiriShortcutButton(
                shortcutType: .lastEvent,
                title: "Последнее событие"
            )
        }
        .padding()
    }
}
