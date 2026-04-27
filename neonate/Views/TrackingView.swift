import SwiftUI
import CoreData

struct TrackingView: View {

    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var childProfileViewModel: ChildProfileViewModel
    @EnvironmentObject var feedingViewModel: FeedingViewModel
    @EnvironmentObject var sleepViewModel: SleepViewModel
    @EnvironmentObject var diaperViewModel: DiaperViewModel

    @State private var showingAddFeeding = false
    @State private var showingAddSleep = false
    @State private var showingAddDiaper = false
    @State private var showingSleepTimer = false
    @State private var showingFeedingList = false
    @State private var showingSleepList = false
    @State private var showingDiaperList = false

    var body: some View {
        mainView
    }

    private var mainScrollView: some View {
        ScrollView {
            VStack(spacing: 24) {

                if let selectedChild = childProfileViewModel.selectedChild {
                    childInfoSection(child: selectedChild)
                } else {
                    noChildView
                }

                if childProfileViewModel.selectedChild != nil {
                    quickTrackingButtons
                }

                if let selectedChild = childProfileViewModel.selectedChild {
                    recentEventsSection(for: selectedChild)
                }
            }
            .padding()
        }
    }

    private var mainView: some View {
        NavigationView {
            mainScrollView
                .navigationTitle(String(localized: "tracking_title"))
                .navigationBarTitleDisplayMode(.large)
                .sheet(isPresented: $showingAddFeeding, onDismiss: reloadIfNeeded) {
                    AddFeedingView(viewModel: feedingViewModel, childViewModel: childProfileViewModel)
                        .environment(\.managedObjectContext, viewContext)
                }
                .sheet(isPresented: $showingAddSleep, onDismiss: reloadIfNeeded) {
                    AddSleepView(viewModel: sleepViewModel, childViewModel: childProfileViewModel)
                        .environment(\.managedObjectContext, viewContext)
                }
                .sheet(isPresented: $showingAddDiaper, onDismiss: reloadIfNeeded) {
                    AddDiaperView()
                        .environmentObject(childProfileViewModel)
                        .environment(\.managedObjectContext, viewContext)
                }
                .fullScreenCover(isPresented: $showingFeedingList, onDismiss: reloadIfNeeded) {
                    FeedingListView(viewModel: feedingViewModel, childViewModel: childProfileViewModel)
                        .environment(\.managedObjectContext, viewContext)
                }
                .fullScreenCover(isPresented: $showingSleepList, onDismiss: reloadIfNeeded) {
                    SleepListView(viewModel: sleepViewModel, childViewModel: childProfileViewModel)
                        .environment(\.managedObjectContext, viewContext)
                }
                .fullScreenCover(isPresented: $showingDiaperList, onDismiss: reloadIfNeeded) {
                    DiaperListView()
                        .environmentObject(childProfileViewModel)
                        .environment(\.managedObjectContext, viewContext)
                }
                .fullScreenCover(isPresented: $showingSleepTimer, onDismiss: reloadIfNeeded) {
                    SleepTimerView(viewModel: sleepViewModel, childViewModel: childProfileViewModel)
                        .environment(\.managedObjectContext, viewContext)
                }
        }
    }

    private func childInfoSection(child: ChildProfile) -> some View {
        HStack {
            if let photoData = child.photoData,
               let uiImage = UIImage(data: photoData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .clipShape(Circle())
            } else {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.gray)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(child.name ?? "")
                    .font(.title2)
                    .fontWeight(.bold)

                Text(childProfileViewModel.getFormattedAge(for: child))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private var quickTrackingButtons: some View {
        VStack(spacing: 16) {
            Text(String(localized: "tracking_select_event"))
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 12) {
                TrackingButton(
                    title: String(localized: "event_feeding"),
                    subtitle: String(localized: "feeding_type_breast") + ", " + String(localized: "feeding_type_bottle") + " " + String(localized: "feeding_type_solid"),
                    icon: "fork.knife.circle.fill",
                    color: .green
                ) {
                    showingAddFeeding = true
                }

                Menu {
                    Button {
                        showingSleepTimer = true
                    } label: {
                        Label(String(localized: "sleep_timer"), systemImage: "timer")
                    }

                    Button {
                        showingAddSleep = true
                    } label: {
                        Label(String(localized: "sleep_manual_entry"), systemImage: "pencil")
                    }
                } label: {
                    HStack(spacing: 16) {
                        Image(systemName: "moon.zzz.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.indigo)
                            .frame(width: 60)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(String(localized: "event_sleep"))
                                .font(.headline)
                                .foregroundColor(.primary)

                            Text(String(localized: "sleep_timer_start"))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }

                TrackingButton(
                    title: String(localized: "event_diaper"),
                    subtitle: String(localized: "diaper_type_wet") + ", " + String(localized: "diaper_type_dirty"),
                    icon: "drop.fill",
                    color: .blue
                ) {
                    showingAddDiaper = true
                }
            }
        }
    }

    private func recentEventsSection(for child: ChildProfile) -> some View {
        VStack(spacing: 16) {
            Text(String(localized: "tracking_recent"))
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            if let childId = child.id {
                VStack(spacing: 12) {

                    if let lastFeeding = feedingViewModel.feedingEvents.first(where: {
                        guard let ts = $0.timestamp else { return false }
                        return Calendar.current.isDateInToday(ts)
                    }) {
                        LastEventCard(
                            title: String(localized: "event_feeding"),
                            icon: "fork.knife.circle.fill",
                            color: .green,
                            subtitle: localizedFeedingType(lastFeeding.feedingType ?? ""),
                            time: formatTime(lastFeeding.timestamp),
                            action: { showingFeedingList = true }
                        )
                    }

                    // Используем cachedStatistics вместо getStatistics
                    if let sleepStats = sleepViewModel.cachedStatistics, sleepStats.todayCount > 0 {
                        LastEventCard(
                            title: String(localized: "event_sleep"),
                            icon: "moon.zzz.fill",
                            color: .indigo,
                            subtitle: sleepStats.isCurrentlySleeping ? String(localized: "sleep_in_progress") : String(localized: "done"),
                            time: formatTimeSince(sleepStats.timeSinceLastSleep),
                            action: { showingSleepList = true }
                        )
                    }

                    if let lastDiaper = diaperViewModel.diaperEvents.first(where: {
                        guard let ts = $0.timestamp else { return false }
                        return Calendar.current.isDateInToday(ts)
                    }) {
                        LastEventCard(
                            title: String(localized: "event_diaper"),
                            icon: "drop.fill",
                            color: .blue,
                            subtitle: localizedDiaperType(lastDiaper.diaperType ?? ""),
                            time: formatTime(lastDiaper.timestamp),
                            action: { showingDiaperList = true }
                        )
                    }
                }
            }
        }
    }

    private var noChildView: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.crop.circle.badge.plus")
                .font(.system(size: 80))
                .foregroundColor(.gray)

            Text(String(localized: "analytics_no_child_title"))
                .font(.title2)
                .fontWeight(.semibold)

            Text(String(localized: "analytics_no_child_message"))
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
    }

    private func reloadIfNeeded() {
        guard let childId = childProfileViewModel.selectedChild?.id else { return }
        feedingViewModel.loadFeedingEvents(for: childId)
        sleepViewModel.loadSleepEvents(for: childId)
        diaperViewModel.loadDiaperEvents(for: childId)
    }

    private func formatTime(_ date: Date?) -> String {
        guard let date = date else { return "" }

        let interval = Date().timeIntervalSince(date)
        let minutes = Int(interval / 60)

        if minutes < 60 {
            return "\(minutes) \(String(localized: "time_ago_minutes"))"
        } else {
            let hours = minutes / 60
            return "\(hours) \(String(localized: "time_ago_hours"))"
        }
    }

    private func formatTimeSince(_ minutes: Int?) -> String {
        guard let minutes = minutes else { return String(localized: "just_now") }

        if minutes < 60 {
            return "\(minutes) \(String(localized: "time_ago_minutes"))"
        } else {
            let hours = minutes / 60
            return "\(hours) \(String(localized: "time_ago_hours"))"
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

    private func localizedDiaperType(_ type: String) -> String {
        if type == "Мокрый" || type == "Wet" {
            return String(localized: "diaper_type_wet")
        } else if type == "Грязный" || type == "Dirty" {
            return String(localized: "diaper_type_dirty")
        } else if type == "Оба" || type == "Both" {
            return String(localized: "diaper_type_both")
        }
        return type
    }
}

struct TrackingButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 40))
                    .foregroundColor(color)
                    .frame(width: 60)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .accessibilityLabel(String(localized: "add_to").replacingOccurrences(of: "%@", with: title.lowercased()))
    }
}

struct LastEventCard: View {
    let title: String
    let icon: String
    let color: Color
    let subtitle: String
    let time: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                    .frame(width: 40)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Text(time)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
        .accessibilityLabel(String(localized: "view_all").replacingOccurrences(of: "%@", with: title.lowercased()))
    }
}

#if DEBUG
struct TrackingView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext

        TrackingView()
            .environmentObject(ChildProfileViewModel(context: context))
            .environmentObject(FeedingViewModel(context: context))
            .environmentObject(SleepViewModel(context: context))
            .environmentObject(DiaperViewModel(context: context))
            .environment(\.managedObjectContext, context)
    }
}
#endif
