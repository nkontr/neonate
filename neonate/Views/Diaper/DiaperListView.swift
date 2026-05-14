import SwiftUI
import CoreData

struct DiaperListView: View {

    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var childProfileViewModel: ChildProfileViewModel

    @StateObject private var viewModel: DiaperViewModel

    @State private var showingAddDiaperView = false
    @State private var selectedEvent: DiaperEvent?
    @State private var dateFilter: DateFilter = .today

    /// Определяет, открыт ли View через fullScreenCover (требует кастомной кнопки "Назад")
    var isFullScreenPresentation: Bool = false

    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext, isFullScreenPresentation: Bool = false) {
        _viewModel = StateObject(wrappedValue: DiaperViewModel(context: context))
        self.isFullScreenPresentation = isFullScreenPresentation
    }

    var body: some View {
        Group {
            if isFullScreenPresentation {
                NavigationView {
                    contentView
                }
            } else {
                contentView
            }
        }
    }

    private var contentView: some View {
        mainContent
            .navigationTitle(String(localized: "diaper_list_title"))
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                if isFullScreenPresentation {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button {
                            dismiss()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                Text(String(localized: "back"))
                            }
                        }
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    addButton
                }
            }
            .sheet(isPresented: $showingAddDiaperView) {
                AddDiaperView()
                    .environmentObject(childProfileViewModel)
                    .environment(\.managedObjectContext, viewContext)
            }
            .sheet(item: $selectedEvent) { event in
                DiaperDetailView(event: event)
                    .environmentObject(childProfileViewModel)
                    .environment(\.managedObjectContext, viewContext)
            }
            .onChange(of: childProfileViewModel.selectedChild) {
                loadEvents()
            }
            .onAppear {
                loadEvents()
            }
    }

    private var mainContent: some View {
        VStack(spacing: 0) {
            dateFilterPicker

            if viewModel.isLoading {
                MiniLoadingView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if filteredEvents.isEmpty {
                emptyStateView
            } else {
                eventsList
            }
        }
    }

    private var addButton: some View {
        Button {
            showingAddDiaperView = true
        } label: {
            Image(systemName: "plus.circle.fill")
                .font(.title3)
        }
        .accessibilityLabel(String(localized: "add_diaper_change"))
    }

    private var emptyStateView: some View {
        EmptyStateView(
            icon: "drop.fill",
            title: String(localized: "no_records"),
            message: String(localized: "add_first_diaper_change"),
            actionTitle: String(localized: "add"),
            action: { showingAddDiaperView = true }
        )
    }

    private var eventsList: some View {
        List {
            ForEach(filteredEvents) { event in
                EventRow(
                    icon: getDiaperIcon(for: event.diaperType),
                    iconColor: getDiaperColor(for: event.diaperType),
                    title: localizedDiaperType(event.diaperType),
                    subtitle: event.notes ?? "",
                    timestamp: formatTime(event.timestamp),
                    details: nil
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    selectedEvent = event
                }
            }
            .onDelete(perform: deleteEvents)
        }
        .listStyle(.insetGrouped)
    }

    private var dateFilterPicker: some View {
        Picker(String(localized: "period_label"), selection: $dateFilter) {
            Text(String(localized: "today_label")).tag(DateFilter.today)
            Text(String(localized: "yesterday_label")).tag(DateFilter.yesterday)
            Text(String(localized: "week_label")).tag(DateFilter.week)
            Text(String(localized: "month_label")).tag(DateFilter.month)
        }
        .pickerStyle(.segmented)
        .padding()
    }

    private var filteredEvents: [DiaperEvent] {
        let calendar = Calendar.current
        let now = Date()

        return viewModel.diaperEvents.filter { event in
            guard let timestamp = event.timestamp else { return false }

            switch dateFilter {
            case .today:
                return calendar.isDateInToday(timestamp)
            case .yesterday:
                return calendar.isDateInYesterday(timestamp)
            case .week:
                guard let weekAgo = calendar.date(byAdding: .day, value: -7, to: now) else { return false }
                return timestamp >= weekAgo
            case .month:
                guard let monthAgo = calendar.date(byAdding: .month, value: -1, to: now) else { return false }
                return timestamp >= monthAgo
            }
        }
    }

    private func loadEvents() {
        guard let childId = childProfileViewModel.selectedChild?.id else { return }
        viewModel.loadDiaperEvents(for: childId)
    }

    private func deleteEvents(at offsets: IndexSet) {
        guard let childId = childProfileViewModel.selectedChild?.id else { return }

        Task {
            for index in offsets {
                let event = filteredEvents[index]
                await viewModel.deleteDiaperChange(event, childId: childId)
            }
        }
    }

    private func localizedDiaperType(_ type: String?) -> String {
        guard let type = type else {
            return String(localized: "diaper_change_default")
        }

        let normalized = type.trimmingCharacters(in: .whitespaces)

        // Russian and English variants
        if normalized == "Мокрый" || normalized == "Wet" {
            return String(localized: "diaper_type_wet")
        } else if normalized == "Грязный" || normalized == "Dirty" {
            return String(localized: "diaper_type_dirty")
        } else if normalized == "Оба" || normalized == "Both" {
            return String(localized: "diaper_type_both")
        }

        return type
    }

    private func getDiaperIcon(for type: String?) -> String {
        guard let type = type else { return "drop.fill" }

        let normalized = type.trimmingCharacters(in: .whitespaces)

        // Check both Russian and English variants
        if normalized == "Мокрый" || normalized == "Wet" {
            return "drop.fill"
        } else if normalized == "Грязный" || normalized == "Dirty" {
            return "sparkles"
        } else if normalized == "Оба" || normalized == "Both" {
            return "drop.triangle.fill"
        }

        return "drop.fill"
    }

    private func getDiaperColor(for type: String?) -> Color {
        guard let type = type else { return .blue }

        let normalized = type.trimmingCharacters(in: .whitespaces)

        // Check both Russian and English variants
        if normalized == "Мокрый" || normalized == "Wet" {
            return .blue
        } else if normalized == "Грязный" || normalized == "Dirty" {
            return .brown
        } else if normalized == "Оба" || normalized == "Both" {
            return .orange
        }

        return .blue
    }

    private func formatTime(_ date: Date?) -> String {
        guard let date = date else { return "" }

        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short

        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return String(localized: "today_at").replacingOccurrences(of: "%@", with: formatter.string(from: date))
        } else if calendar.isDateInYesterday(date) {
            return String(localized: "yesterday_at").replacingOccurrences(of: "%@", with: formatter.string(from: date))
        } else {
            formatter.dateStyle = .short
            return formatter.string(from: date)
        }
    }
}

enum DateFilter {
    case today
    case yesterday
    case week
    case month
}

#if DEBUG
struct DiaperListView_Previews: PreviewProvider {
    static var previews: some View {
        DiaperListView(context: PersistenceController.preview.container.viewContext)
            .environmentObject(ChildProfileViewModel(context: PersistenceController.preview.container.viewContext))
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
#endif
