import SwiftUI

struct SleepListView: View {

    @ObservedObject var viewModel: SleepViewModel
    @ObservedObject var childViewModel: ChildProfileViewModel

    @State private var selectedRange: DateRangePicker.DateRange = .today
    @State private var showAddSleep = false
    @State private var showSleepTimer = false

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                DateRangePicker(selectedRange: $selectedRange)
                    .padding()

                if viewModel.currentSleepSession != nil {
                    Button {
                        showSleepTimer = true
                    } label: {
                        HStack {
                            Image(systemName: "moon.zzz.fill")
                                .foregroundColor(.purple)
                            Text("Ребенок спит")
                                .fontWeight(.medium)
                            Spacer()
                            Text(formatDuration(viewModel.currentSleepDuration))
                                .font(.headline)
                        }
                        .padding()
                        .background(Color.purple.opacity(0.1))
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                }

                if viewModel.sleepEvents.isEmpty {
                    EmptyStateView(
                        icon: "bed.double.fill",
                        title: "Нет записей о сне",
                        message: "Начните отслеживать сон вашего малыша",
                        actionTitle: "Начать отслеживание",
                        action: { showSleepTimer = true }
                    )
                } else {
                    List {
                        ForEach(filteredEvents, id: \.id) { event in
                            NavigationLink(destination: SleepDetailView(event: event, viewModel: viewModel, childViewModel: childViewModel)) {
                                EventRow(
                                    icon: "bed.double.fill",
                                    iconColor: .purple,
                                    title: sleepTitle(event),
                                    subtitle: event.quality ?? "Качество не указано",
                                    timestamp: formatTimestamp(event.startTime),
                                    details: sleepDetails(event)
                                )
                            }
                        }
                        .onDelete { indexSet in
                            deleteEvents(at: indexSet)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Сон")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            showSleepTimer = true
                        } label: {
                            Label("Начать таймер", systemImage: "timer")
                        }
                        Button {
                            showAddSleep = true
                        } label: {
                            Label("Добавить завершенный", systemImage: "plus")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showSleepTimer) {
                SleepTimerView(viewModel: viewModel, childViewModel: childViewModel)
            }
            .sheet(isPresented: $showAddSleep) {
                AddSleepView(viewModel: viewModel, childViewModel: childViewModel)
            }
            .onAppear {
                if let childId = childViewModel.selectedChild?.id {
                    viewModel.loadSleepEvents(for: childId)
                }
            }
        }
    }

    private var filteredEvents: [SleepEvent] {
        let dates = DateRangePicker(selectedRange: .constant(selectedRange)).getDates()
        return viewModel.sleepEvents.filter { event in
            guard let startTime = event.startTime else { return false }
            return startTime >= dates.startDate && startTime <= dates.endDate
        }
    }

    private func sleepTitle(_ event: SleepEvent) -> String {
        if let location = event.location {
            return "Сон в \(location)"
        }
        return "Сон"
    }

    private func sleepDetails(_ event: SleepEvent) -> String {
        if event.endTime == nil {
            return "В процессе..."
        }
        let hours = event.duration / 60
        let minutes = event.duration % 60
        return "Длительность: \(hours)ч \(minutes)м"
    }

    private func formatTimestamp(_ date: Date?) -> String {
        guard let date = date else { return "" }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        return String(format: "%02d:%02d", hours, minutes)
    }

    private func deleteEvents(at offsets: IndexSet) {
        guard let childId = childViewModel.selectedChild?.id else { return }
        Task {
            for index in offsets {
                let event = filteredEvents[index]
                await viewModel.deleteSleep(event, childId: childId)
            }
        }
    }
}
