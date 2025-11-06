import Foundation
import UserNotifications
import UIKit

enum NotificationCategory: String {
    case feedingReminder = "FEEDING_REMINDER"
    case sleepReminder = "SLEEP_REMINDER"
    case diaperReminder = "DIAPER_REMINDER"
}

enum NotificationAction: String {
    case markAsDone = "MARK_AS_DONE"
    case snooze10 = "SNOOZE_10"
    case snooze15 = "SNOOZE_15"
    case snooze30 = "SNOOZE_30"
    case startSleep = "START_SLEEP"
}

class NotificationService: NSObject {

    static let shared = NotificationService()

    private override init() {
        super.init()
        setupNotificationCategories()
    }

    private let notificationCenter = UNUserNotificationCenter.current()

    var onNotificationAction: ((String, NotificationAction) -> Void)?

    private func setupNotificationCategories() {

        let feedingDoneAction = UNNotificationAction(
            identifier: NotificationAction.markAsDone.rawValue,
            title: "Отметить выполненным",
            options: [.foreground]
        )
        let feedingSnoozeAction = UNNotificationAction(
            identifier: NotificationAction.snooze10.rawValue,
            title: "Отложить на 10 мин",
            options: []
        )
        let feedingCategory = UNNotificationCategory(
            identifier: NotificationCategory.feedingReminder.rawValue,
            actions: [feedingDoneAction, feedingSnoozeAction],
            intentIdentifiers: [],
            options: []
        )

        let sleepStartAction = UNNotificationAction(
            identifier: NotificationAction.startSleep.rawValue,
            title: "Начать сон",
            options: [.foreground]
        )
        let sleepSnoozeAction = UNNotificationAction(
            identifier: NotificationAction.snooze15.rawValue,
            title: "Отложить на 15 мин",
            options: []
        )
        let sleepCategory = UNNotificationCategory(
            identifier: NotificationCategory.sleepReminder.rawValue,
            actions: [sleepStartAction, sleepSnoozeAction],
            intentIdentifiers: [],
            options: []
        )

        let diaperDoneAction = UNNotificationAction(
            identifier: NotificationAction.markAsDone.rawValue,
            title: "Отметить выполненным",
            options: [.foreground]
        )
        let diaperSnoozeAction = UNNotificationAction(
            identifier: NotificationAction.snooze30.rawValue,
            title: "Отложить на 30 мин",
            options: []
        )
        let diaperCategory = UNNotificationCategory(
            identifier: NotificationCategory.diaperReminder.rawValue,
            actions: [diaperDoneAction, diaperSnoozeAction],
            intentIdentifiers: [],
            options: []
        )

        notificationCenter.setNotificationCategories([
            feedingCategory,
            sleepCategory,
            diaperCategory
        ])
    }

    func requestAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        let options: UNAuthorizationOptions = [.alert, .sound, .badge]

        notificationCenter.requestAuthorization(options: options) { granted, error in
            DispatchQueue.main.async {
                completion(granted, error)
            }
        }
    }

    func checkAuthorizationStatus(completion: @escaping (UNAuthorizationStatus) -> Void) {
        notificationCenter.getNotificationSettings { settings in
            DispatchQueue.main.async {
                completion(settings.authorizationStatus)
            }
        }
    }

    func scheduleNotification(
        title: String,
        body: String,
        date: Date,
        identifier: String,
        repeats: Bool = false,
        category: NotificationCategory? = nil
    ) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        if let category = category {
            content.categoryIdentifier = category.rawValue
        }

        let triggerDate = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: date
        )

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: triggerDate,
            repeats: repeats
        )

        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )

        notificationCenter.add(request) { error in
            if let error = error {
                print("Ошибка при создании уведомления: \(error)")
            }
        }
    }

    func scheduleNotification(
        title: String,
        body: String,
        timeInterval: TimeInterval,
        identifier: String,
        category: NotificationCategory? = nil
    ) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        if let category = category {
            content.categoryIdentifier = category.rawValue
        }

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: timeInterval,
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )

        notificationCenter.add(request) { error in
            if let error = error {
                print("Ошибка при создании уведомления: \(error)")
            }
        }
    }

    func cancelNotification(withIdentifier identifier: String) {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    func cancelAllNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
    }

    func getPendingNotifications(completion: @escaping ([UNNotificationRequest]) -> Void) {
        notificationCenter.getPendingNotificationRequests { requests in
            DispatchQueue.main.async {
                completion(requests)
            }
        }
    }

    func getAllPendingNotifications(completion: @escaping ([UNNotificationRequest]) -> Void) {
        getPendingNotifications(completion: completion)
    }

    func cancelNotification(id: String) {
        cancelNotification(withIdentifier: id)
    }

    func cancelAll() {
        cancelAllNotifications()
    }

    func setBadgeCount(_ count: Int) {
        UNUserNotificationCenter.current().setBadgeCount(count) { error in
            if let error = error {
                print("Ошибка при установке значка: \(error)")
            }
        }
    }

    func clearBadge() {
        setBadgeCount(0)
    }

    func registerDeviceToken(_ deviceToken: Data) {
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let token = tokenParts.joined()
        print("Device Token: \(token)")

    }

    func handleRemoteNotificationRegistrationError(_ error: Error) {
        print("Ошибка регистрации для удаленных уведомлений: \(error.localizedDescription)")
    }

    func handleRemoteNotification(
        _ userInfo: [AnyHashable: Any],
        completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        print("Получено удаленное уведомление: \(userInfo)")

        completionHandler(.newData)
    }
}

extension NotificationService: UNUserNotificationCenterDelegate {

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {

        completionHandler([.banner, .sound, .badge])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let identifier = response.notification.request.identifier
        let actionIdentifier = response.actionIdentifier

        print("Пользователь нажал на уведомление: \(identifier), действие: \(actionIdentifier)")

        if actionIdentifier != UNNotificationDefaultActionIdentifier {
            handleNotificationAction(identifier: identifier, actionIdentifier: actionIdentifier)
        }

        completionHandler()
    }

    private func handleNotificationAction(identifier: String, actionIdentifier: String) {
        guard let action = NotificationAction(rawValue: actionIdentifier) else {
            return
        }

        onNotificationAction?(identifier, action)

        switch action {
        case .snooze10:
            handleSnooze(identifier: identifier, minutes: 10)
        case .snooze15:
            handleSnooze(identifier: identifier, minutes: 15)
        case .snooze30:
            handleSnooze(identifier: identifier, minutes: 30)
        default:
            break
        }
    }

    private func handleSnooze(identifier: String, minutes: Int) {

        getPendingNotifications { [weak self] requests in
            guard let self = self,
                  let originalRequest = requests.first(where: { $0.identifier == identifier })
            else { return }

            self.cancelNotification(withIdentifier: identifier)

            let content = originalRequest.content
            self.scheduleNotification(
                title: content.title,
                body: content.body,
                timeInterval: TimeInterval(minutes * 60),
                identifier: identifier,
                category: NotificationCategory(rawValue: content.categoryIdentifier)
            )

            print("Уведомление \(identifier) отложено на \(minutes) минут")
        }
    }
}
