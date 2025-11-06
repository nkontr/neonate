import SwiftUI
import CoreData

struct DashboardView: View {

    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var childProfileViewModel: ChildProfileViewModel
    @EnvironmentObject var feedingViewModel: FeedingViewModel
    @EnvironmentObject var sleepViewModel: SleepViewModel
    @EnvironmentObject var diaperViewModel: DiaperViewModel

    @State private var showingAddFeeding = false
    @State private var showingAddSleep = false
    @State private var showingAddDiaper = false
    @State private var showingChildSelector = false

    var body: some View {
        mainView
    }

    private var mainView: some View {
        NavigationView {
            mainContent
                .navigationTitle(String(localized: "dashboard_title"))
                .navigationBarTitleDisplayMode(.large)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        toolbarButton
                    }
                }
                .sheet(isPresented: $showingAddFeeding) {
                    AddFeedingView(viewModel: feedingViewModel, childViewModel: childProfileViewModel)
                        .environment(\.managedObjectContext, viewContext)
                }
                .sheet(isPresented: $showingAddSleep) {
                    AddSleepView(viewModel: sleepViewModel, childViewModel: childProfileViewModel)
                        .environment(\.managedObjectContext, viewContext)
                }
                .sheet(isPresented: $showingAddDiaper) {
                    AddDiaperView()
                        .environmentObject(childProfileViewModel)
                        .environment(\.managedObjectContext, viewContext)
                }
                .sheet(isPresented: $showingChildSelector) {
                    ChildrenListView(viewModel: childProfileViewModel)
                        .environment(\.managedObjectContext, viewContext)
                }
                .onChange(of: childProfileViewModel.selectedChild) { newChild in
                    if let childId = newChild?.id {
                        loadDataForChild(childId)
                    }
                }
                .onAppear {
                    if let childId = childProfileViewModel.selectedChild?.id {
                        loadDataForChild(childId)
                    }
                }
        }
    }

    private var toolbarButton: some View {
        Button {
            showingChildSelector = true
        } label: {
            Image(systemName: "person.2.fill")
        }
        .accessibilityLabel(String(localized: "a11y_select_child"))
        .accessibilityHint(String(localized: "dashboard_select_child"))
    }

    private var mainContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                childSelectorSection

                if let selectedChild = childProfileViewModel.selectedChild {
                    statsCardsSection(for: selectedChild)
                    quickActionsSection
                    recentEventsSection(for: selectedChild)
                } else {
                    noChildSelectedView
                }
            }
            .padding()
        }
    }

    private var childSelectorSection: some View {
        VStack(spacing: 12) {
            if let selectedChild = childProfileViewModel.selectedChild {
                Button {
                    showingChildSelector = true
                } label: {
                    HStack {
                        if let photoData = selectedChild.photoData,
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
                                .accessibilityHidden(true)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(selectedChild.name ?? "")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)

                            Text(childProfileViewModel.getFormattedAge(for: selectedChild))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                            .accessibilityHidden(true)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(selectedChild.name ?? ""), \(childProfileViewModel.getFormattedAge(for: selectedChild))")
                    .accessibilityHint(String(localized: "dashboard_select_child"))
                    .accessibilityAddTraits(.isButton)
                }
            }
        }
    }

    private func statsCardsSection(for child: ChildProfile) -> some View {
        VStack(spacing: 12) {

            if let childId = child.id {
                FeedingStatsCard(statistics: feedingViewModel.getStatistics(for: childId))

                SleepStatsCard(statistics: sleepViewModel.getStatistics(for: childId))

                DiaperStatsCard(statistics: diaperViewModel.getStatistics(for: childId))
            }
        }
    }

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "dashboard_quick_add"))
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            HStack(spacing: 12) {
                QuickActionButton(
                    title: String(localized: "event_feeding"),
                    icon: "fork.knife.circle.fill",
                    color: .green
                ) {
                    showingAddFeeding = true
                }

                QuickActionButton(
                    title: String(localized: "event_sleep"),
                    icon: "moon.zzz.fill",
                    color: .indigo
                ) {
                    showingAddSleep = true
                }

                QuickActionButton(
                    title: String(localized: "event_diaper"),
                    icon: "drop.fill",
                    color: .blue
                ) {
                    showingAddDiaper = true
                }
            }
        }
    }

    private func recentEventsSection(for child: ChildProfile) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(String(localized: "dashboard_today_events"))
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)

                Spacer()
            }

            if let childId = child.id {
                let feedingEvents = feedingViewModel.getFeedingsToday(for: childId)
                let sleepEvents = sleepViewModel.getStatistics(for: childId).todayCount
                let diaperEvents = diaperViewModel.getEventsToday(for: childId)

                VStack(spacing: 8) {
                    RecentEventRow(
                        icon: "fork.knife.circle.fill",
                        color: .green,
                        title: String(localized: "event_feeding"),
                        count: feedingEvents.count
                    )

                    RecentEventRow(
                        icon: "moon.zzz.fill",
                        color: .indigo,
                        title: String(localized: "sleep_list_title"),
                        count: sleepEvents
                    )

                    RecentEventRow(
                        icon: "drop.fill",
                        color: .blue,
                        title: String(localized: "diaper_list_title"),
                        count: diaperEvents.count
                    )
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .accessibilityElement(children: .contain)
            }
        }
    }

    private var noChildSelectedView: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.crop.circle.badge.plus")
                .font(.system(size: 80))
                .foregroundColor(.gray)
                .accessibilityHidden(true)

            Text(String(localized: "dashboard_no_child_title"))
                .font(.title2)
                .fontWeight(.semibold)

            Text(String(localized: "dashboard_no_child_message"))
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button {
                showingChildSelector = true
            } label: {
                Text(String(localized: "dashboard_add_child_button"))
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            .buttonAccessibility(
                label: String(localized: "dashboard_add_child_button"),
                hint: String(localized: "dashboard_no_child_message")
            )
        }
        .padding()
        .emptyStateAccessibility(
            message: String(localized: "dashboard_no_child_title"),
            actionLabel: String(localized: "dashboard_add_child_button")
        )
    }

    private func loadDataForChild(_ childId: UUID) {
        feedingViewModel.loadFeedingEvents(for: childId)
        sleepViewModel.loadSleepEvents(for: childId)
        diaperViewModel.loadDiaperEvents(for: childId)
    }
}

struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title)
                    .foregroundColor(color)
                    .accessibilityHidden(true)

                Text(title)
                    .font(.caption)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonAccessibility(
            label: String(format: NSLocalizedString("add", comment: ""), title),
            hint: nil
        )
        .ensureMinimumTouchTarget()
    }
}

struct RecentEventRow: View {
    let icon: String
    let color: Color
    let title: String
    let count: Int

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title3)
                .accessibilityHidden(true)

            Text(title)
                .font(.body)

            Spacer()

            Text("\(count)")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(count)")
        .accessibilityAddTraits(.isStaticText)
    }
}

#if DEBUG
struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext

        DashboardView()
            .environmentObject(ChildProfileViewModel(context: context))
            .environmentObject(FeedingViewModel(context: context))
            .environmentObject(SleepViewModel(context: context))
            .environmentObject(DiaperViewModel(context: context))
            .environment(\.managedObjectContext, context)
    }
}
#endif
