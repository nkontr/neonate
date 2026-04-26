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
                        title: String(localized: "feeding_empty"),
                        message: String(localized: "feeding_empty_message"),
                        actionTitle: String(localized: "feeding_add"),
                        action: { showAddFeeding = true }
                    )
                } else {
                    List {
                        ForEach(filteredEvents, id: \.id) { event in
                            NavigationLink(destination: FeedingDetailView(event: event, viewModel: viewModel, childViewModel: childViewModel)) {
                                EventRow(
                                    icon: "fork.knife",
                                    iconColor: .orange,
                                    title: event.feedingType ?? String(localized: "feeding_default_title"),
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
            .navigationTitle(String(localized: "feeding_list_title"))
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
            return localizedBreast(breast)
        }
        return localizedFeedingType(event.feedingType ?? "")
    }

    private func feedingDetails(_ event: FeedingEvent) -> String {
        var parts: [String] = []

        if event.duration > 0 {
            let label = String(localized: "feeding_duration_label").replacingOccurrences(of: "%d", with: "\(event.duration)")
            parts.append(label)
        }

        if event.volume > 0 {
            let label = String(localized: "feeding_volume_label").replacingOccurrences(of: "%d", with: "\(Int(event.volume))")
            parts.append(label)
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
            return String(localized: "yesterday_label")
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

    private func localizedFeedingType(_ type: String) -> String {
        if type == "Грудное" || type == "Грудное вскармливание" {
            return String(localized: "feeding_type_breast_feeding")
        } else if type == "Бутылочка" || type == "Кормление из бутылочки" {
            return String(localized: "feeding_type_bottle_feeding")
        } else if type == "Прикорм" {
            return String(localized: "feeding_type_complementary_feeding")
        } else if type == "Breast" || type == "Breastfeeding" {
            return String(localized: "feeding_type_breast_feeding")
        } else if type == "Bottle" || type == "Bottle feeding" {
            return String(localized: "feeding_type_bottle_feeding")
        } else if type == "Solid" || type == "Complementary feeding" {
            return String(localized: "feeding_type_complementary_feeding")
        }
        return type
    }

    private func localizedBreast(_ breast: String) -> String {
        let normalized = breast.trimmingCharacters(in: .whitespaces)

        if normalized == "Левая" || normalized == "Left" {
            return String(localized: "feeding_breast_left")
        } else if normalized == "Правая" || normalized == "Right" {
            return String(localized: "feeding_breast_right")
        } else if normalized == "Обе" || normalized == "Both" {
            return String(localized: "feeding_breast_both")
        }

        return breast
    }
}
