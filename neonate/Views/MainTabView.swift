import SwiftUI
import CoreData

struct MainTabView: View {

    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var authViewModel: AuthViewModel

    @StateObject private var childProfileViewModel: ChildProfileViewModel
    @StateObject private var feedingViewModel: FeedingViewModel
    @StateObject private var sleepViewModel: SleepViewModel
    @StateObject private var diaperViewModel: DiaperViewModel
    @StateObject private var reminderViewModel: ReminderViewModel

    @State private var selectedTab: Tab = .dashboard

    init() {
        let context = PersistenceController.shared.container.viewContext
        _childProfileViewModel = StateObject(wrappedValue: ChildProfileViewModel(context: context))
        _feedingViewModel = StateObject(wrappedValue: FeedingViewModel(context: context))
        _sleepViewModel = StateObject(wrappedValue: SleepViewModel(context: context))
        _diaperViewModel = StateObject(wrappedValue: DiaperViewModel(context: context))
        _reminderViewModel = StateObject(wrappedValue: ReminderViewModel(context: context))
    }

    var body: some View {
        let _ = Self._printChanges()
        TabView(selection: $selectedTab) {

            DashboardView(selectedTab: $selectedTab)
                .environmentObject(childProfileViewModel)
                .environmentObject(feedingViewModel)
                .environmentObject(sleepViewModel)
                .environmentObject(diaperViewModel)
                .environment(\.managedObjectContext, viewContext)
                .tabItem {
                    Label(String(localized: "tab_dashboard"), systemImage: "house.fill")
                }
                .tag(Tab.dashboard)
                .accessibilityLabel(String(localized: "tab_dashboard"))

            TrackingView()
                .environmentObject(childProfileViewModel)
                .environmentObject(feedingViewModel)
                .environmentObject(sleepViewModel)
                .environmentObject(diaperViewModel)
                .environment(\.managedObjectContext, viewContext)
                .tabItem {
                    Label(String(localized: "tab_tracking"), systemImage: "plus.circle.fill")
                }
                .tag(Tab.tracking)
                .accessibilityLabel(String(localized: "tab_tracking"))

            AnalyticsView()
                .environmentObject(childProfileViewModel)
                .environment(\.managedObjectContext, viewContext)
                .tabItem {
                    Label(String(localized: "tab_analytics"), systemImage: "chart.bar.fill")
                }
                .tag(Tab.analytics)
                .accessibilityLabel(String(localized: "tab_analytics"))

            SettingsView()
                .environmentObject(authViewModel)
                .environmentObject(childProfileViewModel)
                .environmentObject(reminderViewModel)
                .environment(\.managedObjectContext, viewContext)
                .tabItem {
                    Label(String(localized: "tab_settings"), systemImage: "gearshape.fill")
                }
                .tag(Tab.settings)
                .accessibilityLabel(String(localized: "tab_settings"))
        }
        .accentColor(.blue)
        .onAppear {
            // Set current user ID for child filtering
            if let userId = authViewModel.currentUser?.id {
                childProfileViewModel.setCurrentUser(userId: userId)
            }

            if let childId = childProfileViewModel.selectedChild?.id {
                loadDataForChild(childId)
            }
        }
        .onChange(of: authViewModel.currentUser?.id) { _, newUserId in
            // User changed - update child filtering
            if let userId = newUserId {
                childProfileViewModel.setCurrentUser(userId: userId)
            }
        }
        .onChange(of: childProfileViewModel.selectedChild) { _, newChild in
            if let childId = newChild?.id {
                loadDataForChild(childId)
            }
        }
    }

    private func loadDataForChild(_ childId: UUID) {
        feedingViewModel.loadFeedingEvents(for: childId)
        sleepViewModel.loadSleepEvents(for: childId)
        diaperViewModel.loadDiaperEvents(for: childId)
        reminderViewModel.loadReminders(for: childId)
    }
}

enum Tab {
    case dashboard
    case tracking
    case analytics
    case settings
}

#if DEBUG
struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
            .environmentObject(AuthViewModel.preview)
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
#endif
