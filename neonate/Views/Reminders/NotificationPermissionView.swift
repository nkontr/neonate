import SwiftUI
import UserNotifications

struct NotificationPermissionView: View {

    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: ReminderViewModel

    @State private var isRequesting: Bool = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "bell.badge.fill")
                .font(.system(size: 80))
                .foregroundColor(.orange)

            Text(String(localized: "notification_permission_title"))
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            VStack(spacing: 12) {
                PermissionReasonRow(
                    icon: "clock.fill",
                    text: String(localized: "notification_permission_reason_timely")
                )

                PermissionReasonRow(
                    icon: "bell.fill",
                    text: String(localized: "notification_permission_reason_customizable")
                )

                PermissionReasonRow(
                    icon: "checkmark.circle.fill",
                    text: String(localized: "notification_permission_reason_quick_actions")
                )
            }
            .padding(.horizontal)

            Spacer()

            VStack(spacing: 12) {
                if viewModel.notificationPermissionStatus == .denied {

                    Button {
                        viewModel.openAppSettings()
                    } label: {
                        Text(String(localized: "notification_permission_open_settings"))
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                    }

                    Text(String(localized: "notification_permission_denied_message"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                } else {

                    Button {
                        requestPermission()
                    } label: {
                        if isRequesting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .frame(maxWidth: .infinity)
                                .padding()
                        } else {
                            Text(String(localized: "notification_permission_allow"))
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(12)
                        }
                    }
                    .disabled(isRequesting)

                    Button(String(localized: "notification_permission_skip")) {
                        dismiss()
                    }
                    .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 32)
        }
        .padding()
    }

    private func requestPermission() {
        isRequesting = true

        Task {
            await viewModel.requestNotificationPermission()

            // Подождем небольшую задержку для обновления статуса
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5 секунды

            // Перепроверим статус
            viewModel.checkNotificationPermission()

            isRequesting = false

            if viewModel.notificationPermissionStatus == .authorized {
                dismiss()
            }
        }
    }
}

struct PermissionReasonRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 24)

            Text(text)
                .font(.body)
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)

            Spacer()
        }
    }
}

#if DEBUG
struct NotificationPermissionView_Previews: PreviewProvider {
    static var previews: some View {
        NotificationPermissionView(viewModel: ReminderViewModel.preview)
    }
}
#endif
