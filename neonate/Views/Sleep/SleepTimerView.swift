import SwiftUI

struct SleepTimerView: View {

    @Environment(\.dismiss) private var dismiss

    @ObservedObject var viewModel: SleepViewModel
    @ObservedObject var childViewModel: ChildProfileViewModel

    @State private var location: String = String(localized: "sleep_location_crib")
    @State private var quality: String = String(localized: "sleep_quality_good")
    @State private var notes: String = ""

    var locationOptions: [String] {
        [
            String(localized: "sleep_location_crib"),
            String(localized: "sleep_location_stroller"),
            String(localized: "sleep_location_arms"),
            String(localized: "sleep_location_car")
        ]
    }

    var qualityOptions: [String] {
        [
            String(localized: "sleep_quality_excellent"),
            String(localized: "sleep_quality_good"),
            String(localized: "sleep_quality_normal"),
            String(localized: "sleep_quality_restless")
        ]
    }

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
                        Text(String(localized: "sleep_child_sleeping"))
                            .font(.title3)
                            .foregroundColor(.secondary)
                    } else {
                        Text(String(localized: "sleep_ready_tracking"))
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                if viewModel.currentSleepSession == nil {
                    VStack(spacing: 16) {
                        Picker(String(localized: "sleep_location"), selection: $location) {
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
                        Text(String(localized: "sleep_finish"))
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
                        Text(String(localized: "sleep_start_tracking"))
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.purple)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                }

                Spacer()
            }
            .navigationTitle(String(localized: "sleep_timer"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "close")) { dismiss() }
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
