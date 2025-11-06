import SwiftUI
import CoreData

struct MainTabView: View {

    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var authViewModel: AuthViewModel

    @StateObject private var childProfileViewModel: ChildProfileViewModel
    @StateObject private var feedingViewModel: FeedingViewModel
    @StateObject private var sleepViewModel: SleepViewModel
    @StateObject private var diaperViewModel: DiaperViewModel

    @State private var selectedTab: Tab = .dashboard

    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        _childProfileViewModel = StateObject(wrappedValue: ChildProfileViewModel(context: context))
        _feedingViewModel = StateObject(wrappedValue: FeedingViewModel(context: context))
        _sleepViewModel = StateObject(wrappedValue: SleepViewModel(context: context))
        _diaperViewModel = StateObject(wrappedValue: DiaperViewModel(context: context))
    }

    var body: some View {
        TabView(selection: $selectedTab) {

            DashboardView()
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
                .environment(\.managedObjectContext, viewContext)
                .tabItem {
                    Label(String(localized: "tab_settings"), systemImage: "gearshape.fill")
                }
                .tag(Tab.settings)
                .accessibilityLabel(String(localized: "tab_settings"))
        }
        .accentColor(.blue)
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
        MainTabView(context: PersistenceController.preview.container.viewContext)
            .environmentObject(AuthViewModel.preview)
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
#endif
