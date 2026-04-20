import SwiftUI
import CoreData

struct DiaperListView: View {

    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var childProfileViewModel: ChildProfileViewModel

    @StateObject private var viewModel: DiaperViewModel

    @State private var showingAddDiaperView = false
    @State private var selectedEvent: DiaperEvent?
    @State private var dateFilter: DateFilter = .today

    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        _viewModel = StateObject(wrappedValue: DiaperViewModel(context: context))
    }

    var body: some View {
        bodyContent
    }

    private var bodyContent: some View {
        NavigationView {
            mainContent
                .navigationTitle("Подгузники")
                .navigationBarTitleDisplayMode(.large)
                .toolbar {
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
                .onChange(of: childProfileViewModel.selectedChild) { _ in
                    loadEvents()
                }
                .onAppear {
                    loadEvents()
                }
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
        .accessibilityLabel("Добавить смену подгузника")
    }

    private var emptyStateView: some View {
        EmptyStateView(
            icon: "drop.fill",
            title: "Нет записей",
            message: "Добавьте первую смену подгузника",
            actionTitle: "Добавить",
            action: { showingAddDiaperView = true }
        )
    }

    private var eventsList: some View {
        List {
            ForEach(filteredEvents) { event in
                EventRow(
                    icon: getDiaperIcon(for: event.diaperType),
                    iconColor: getDiaperColor(for: event.diaperType),
                    title: event.diaperType ?? "Смена подгузника",
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
        Picker("Период", selection: $dateFilter) {
            Text("Сегодня").tag(DateFilter.today)
            Text("Вчера").tag(DateFilter.yesterday)
            Text("Неделя").tag(DateFilter.week)
            Text("Месяц").tag(DateFilter.month)
        }
        .pickerStyle(.segmented)
        .padding()
        .onChange(of: dateFilter) { _ in

        }
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

    private func getDiaperIcon(for type: String?) -> String {
        guard let type = type else { return "drop.fill" }

        switch type {
        case "Мокрый":
            return "drop.fill"
        case "Грязный":
            return "sparkles"
        case "Оба":
            return "drop.triangle.fill"
        default:
            return "drop.fill"
        }
    }

    private func getDiaperColor(for type: String?) -> Color {
        guard let type = type else { return .blue }

        switch type {
        case "Мокрый":
            return .blue
        case "Грязный":
            return .brown
        case "Оба":
            return .orange
        default:
            return .blue
        }
    }

    private func formatTime(_ date: Date?) -> String {
        guard let date = date else { return "" }

        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short

        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Сегодня, \(formatter.string(from: date))"
        } else if calendar.isDateInYesterday(date) {
            return "Вчера, \(formatter.string(from: date))"
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
