import SwiftUI

struct SleepTimerView: View {

    @Environment(\.dismiss) private var dismiss

    @ObservedObject var viewModel: SleepViewModel
    @ObservedObject var childViewModel: ChildProfileViewModel

    @State private var location: String = "Кроватка"
    @State private var quality: String = "Хорошее"
    @State private var notes: String = ""

    let locationOptions = ["Кроватка", "Коляска", "На руках", "В машине"]
    let qualityOptions = ["Отличное", "Хорошее", "Нормальное", "Беспокойное"]

    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Spacer()

                VStack(spacing: 16) {
                    Image(systemName: "moon.zzz.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.purple)

                    Text(formatDuration(viewModel.currentSleepDuration))
                        .font(.system(size: 60, weight: .bold, design: .rounded))
                        .monospacedDigit()

                    if viewModel.currentSleepSession != nil {
                        Text("Ребенок спит")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    } else {
                        Text("Готов к отслеживанию")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                if viewModel.currentSleepSession == nil {
                    VStack(spacing: 16) {
                        Picker("Место сна", selection: $location) {
                            ForEach(locationOptions, id: \.self) { option in
                                Text(option)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }

                if viewModel.currentSleepSession != nil {
                    Button {
                        endSleep()
                    } label: {
                        Text("Завершить сон")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                } else {
                    Button {
                        startSleep()
                    } label: {
                        Text("Начать отслеживание")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.purple)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                }

                if viewModel.currentSleepSession == nil {
                    SiriShortcutButton(
                        shortcutType: .sleepTimer,
                        title: "Скажите Siri для запуска таймера"
                    )
                    .padding(.horizontal)
                }

                Spacer()
            }
            .navigationTitle("Таймер сна")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Закрыть") { dismiss() }
                }
            }
        }
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }

    private func startSleep() {
        guard let childId = childViewModel.selectedChild?.id else { return }
        Task {
            await viewModel.startSleep(
                childId: childId,
                location: location
            )
        }
    }

    private func endSleep() {
        guard let childId = childViewModel.selectedChild?.id else { return }
        Task {
            await viewModel.endSleep(childId: childId, quality: quality)
            dismiss()
        }
    }
}
