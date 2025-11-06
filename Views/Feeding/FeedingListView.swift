import SwiftUI

struct FeedingListView: View {

    @ObservedObject var viewModel: FeedingViewModel
    @ObservedObject var childViewModel: ChildProfileViewModel

    @State private var selectedRange: DateRangePicker.DateRange = .today
    @State private var showAddFeeding = false

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {

                DateRangePicker(selectedRange: $selectedRange)
                    .padding()

                if viewModel.feedingEvents.isEmpty {
                    EmptyStateView(
                        icon: "fork.knife",
                        title: "Нет записей о кормлении",
                        message: "Начните отслеживать кормления вашего малыша",
                        actionTitle: "Добавить кормление",
                        action: { showAddFeeding = true }
                    )
                } else {
                    List {
                        ForEach(filteredEvents, id: \.id) { event in
                            NavigationLink(destination: FeedingDetailView(event: event, viewModel: viewModel, childViewModel: childViewModel)) {
                                EventRow(
                                    icon: "fork.knife",
                                    iconColor: .orange,
                                    title: event.feedingType ?? "Кормление",
                                    subtitle: feedingSubtitle(event),
                                    timestamp: formatTimestamp(event.timestamp),
                                    details: feedingDetails(event)
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
            .navigationTitle("Кормления")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showAddFeeding = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddFeeding) {
                AddFeedingView(viewModel: viewModel, childViewModel: childViewModel)
            }
            .onAppear {
                if let childId = childViewModel.selectedChild?.id {
                    viewModel.loadFeedingEvents(for: childId)
                }
            }
        }
    }

    private var filteredEvents: [FeedingEvent] {
        let dates = DateRangePicker(selectedRange: .constant(selectedRange)).getDates()
        return viewModel.feedingEvents.filter { event in
            guard let timestamp = event.timestamp else { return false }
            return timestamp >= dates.startDate && timestamp <= dates.endDate
        }
    }

    private func feedingSubtitle(_ event: FeedingEvent) -> String {
        if let breast = event.breast {
            return breast
        }
        return event.feedingType ?? ""
    }

    private func feedingDetails(_ event: FeedingEvent) -> String {
        var parts: [String] = []

        if event.duration > 0 {
            parts.append("Длительность: \(event.duration) мин")
        }

        if event.volume > 0 {
            parts.append("Объем: \(Int(event.volume)) мл")
        }

        return parts.joined(separator: " • ")
    }

    private func formatTimestamp(_ date: Date?) -> String {
        guard let date = date else { return "" }

        let calendar = Calendar.current
        let now = Date()

        if calendar.isDateInToday(date) {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return formatter.string(from: date)
        } else if calendar.isDateInYesterday(date) {
            return "Вчера"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            return formatter.string(from: date)
        }
    }

    private func deleteEvents(at offsets: IndexSet) {
        guard let childId = childViewModel.selectedChild?.id else { return }

        Task {
            for index in offsets {
                let event = filteredEvents[index]
                await viewModel.deleteFeeding(event, childId: childId)
            }
        }
    }
}
