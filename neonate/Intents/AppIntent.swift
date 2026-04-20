import Foundation
import AppIntents

@available(iOS 16.0, *)
protocol BabyCareIntent: AppIntent {}

@available(iOS 16.0, *)
struct BabyCareShortcuts: AppShortcutsProvider {

    static var appShortcuts: [AppShortcut] {

        AppShortcut(
            intent: LogFeedingIntent(),
            phrases: [
                "Записать кормление в \(.applicationName)",
                "Я покормил малыша в \(.applicationName)",
                "Покормил ребенка в \(.applicationName)",
                "Add feeding to \(.applicationName)",
                "I fed baby in \(.applicationName)"
            ],
            shortTitle: "Кормление",
            systemImageName: "fork.knife"
        )

        AppShortcut(
            intent: LogSleepIntent(),
            phrases: [
                "Записать сон в \(.applicationName)",
                "Малыш спал в \(.applicationName)",
                "Проспал в \(.applicationName)",
                "Log sleep to \(.applicationName)",
                "Baby slept in \(.applicationName)"
            ],
            shortTitle: "Сон",
            systemImageName: "moon.stars.fill"
        )

        AppShortcut(
            intent: StartSleepTimerIntent(),
            phrases: [
                "Начать отслеживание сна в \(.applicationName)",
                "Малыш засыпает в \(.applicationName)",
                "Start sleep timer in \(.applicationName)",
                "Baby is falling asleep in \(.applicationName)"
            ],
            shortTitle: "Таймер сна",
            systemImageName: "clock.fill"
        )

        AppShortcut(
            intent: LogDiaperIntent(),
            phrases: [
                "Поменял подгузник в \(.applicationName)",
                "Записать смену подгузника в \(.applicationName)",
                "Changed diaper in \(.applicationName)",
                "Log diaper change to \(.applicationName)"
            ],
            shortTitle: "Подгузник",
            systemImageName: "circle.grid.cross.fill"
        )

        AppShortcut(
            intent: GetLastEventIntent(),
            phrases: [
                "Когда было последнее кормление в \(.applicationName)",
                "Последнее событие в \(.applicationName)",
                "Когда меняли подгузник в \(.applicationName)",
                "When was last feeding in \(.applicationName)",
                "Last event in \(.applicationName)"
            ],
            shortTitle: "Последнее событие",
            systemImageName: "clock.arrow.circlepath"
        )
    }

    static var shortcutTileColor: ShortcutTileColor {
        .blue
    }
}
