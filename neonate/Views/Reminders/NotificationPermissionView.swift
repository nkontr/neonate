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

            Text("Разрешите уведомления")
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            VStack(spacing: 12) {
                PermissionReasonRow(
                    icon: "clock.fill",
                    text: "Своевременные напоминания о кормлении, сне и смене подгузников"
                )

                PermissionReasonRow(
                    icon: "bell.fill",
                    text: "Настраиваемые интервалы напоминаний для каждого типа события"
                )

                PermissionReasonRow(
                    icon: "checkmark.circle.fill",
                    text: "Быстрые действия прямо из уведомлений"
                )
            }
            .padding(.horizontal)

            Spacer()

            VStack(spacing: 12) {
                if viewModel.notificationPermissionStatus == .denied {

                    Button {
                        viewModel.openAppSettings()
                    } label: {
                        Text("Открыть настройки")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                    }

                    Text("Разрешения отклонены. Перейдите в настройки для их изменения")
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
                            Text("Разрешить уведомления")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(12)
                        }
                    }
                    .disabled(isRequesting)

                    Button("Пропустить") {
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
