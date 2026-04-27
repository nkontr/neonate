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
    @State private var showingSleepTimer = false
    @State private var showingChildSelector = false

    var body: some View {
        let _ = Self._printChanges()
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
                .sheet(isPresented: $showingChildSelector) {
                    ChildrenListView(viewModel: childProfileViewModel)
                        .environment(\.managedObjectContext, viewContext)
                }
                .fullScreenCover(isPresented: $showingSleepTimer, onDismiss: reloadIfNeeded) {
                    SleepTimerView(viewModel: sleepViewModel, childViewModel: childProfileViewModel)
                        .environment(\.managedObjectContext, viewContext)
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
        ZStack {
            LinearGradient(
                colors: [
                    Color(.systemBackground),
                    Color.blue.opacity(0.03),
                    Color.purple.opacity(0.03)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    childSelectorSection

                    if let selectedChild = childProfileViewModel.selectedChild {
                        statsCardsSection(for: selectedChild)
                        quickActionsSection
                    } else {
                        noChildSelectedView
                    }
                }
                .padding()
            }
        }
    }

    private var childSelectorSection: some View {
        VStack(spacing: 12) {
            if let selectedChild = childProfileViewModel.selectedChild {
                Button {
                    showingChildSelector = true
                } label: {
                    HStack(spacing: 16) {
                        ZStack {
                            if let photoData = selectedChild.photoData,
                               let uiImage = UIImage(data: photoData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 70, height: 70)
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle()
                                            .strokeBorder(
                                                LinearGradient(
                                                    colors: [.white.opacity(0.5), .clear],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ),
                                                lineWidth: 2
                                            )
                                    )
                            } else {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.2)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 70, height: 70)
                                    .overlay(
                                        Image(systemName: "person.circle.fill")
                                            .font(.system(size: 50))
                                            .foregroundStyle(
                                                LinearGradient(
                                                    colors: [.blue, .purple],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                    )
                                    .accessibilityHidden(true)
                            }
                        }
                        .shadow(color: .blue.opacity(0.2), radius: 8, x: 0, y: 4)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(selectedChild.name ?? "")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)

                            Text(childProfileViewModel.getFormattedAge(for: selectedChild))
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary.opacity(0.7))
                            .font(.title3)
                            .accessibilityHidden(true)
                    }
                    .liquidGlassCard(backgroundColor: .blue, cornerRadius: 20)
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
            if let stats = feedingViewModel.cachedStatistics {
                FeedingStatsCard(statistics: stats)
                    .id("feeding")
            }
            if let stats = sleepViewModel.cachedStatistics {
                SleepStatsCard(statistics: stats)
                    .id("sleep")
            }
            if let stats = diaperViewModel.cachedStatistics {
                DiaperStatsCard(statistics: stats)
                    .id("diaper")
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
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.indigo.opacity(0.3), Color.indigo.opacity(0.15)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 50, height: 50)
                                .shadow(color: Color.indigo.opacity(0.3), radius: 8, x: 0, y: 4)

                            Image(systemName: "moon.zzz.fill")
                                .font(.title2)
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color.indigo, Color.indigo.opacity(0.8)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }

                        Text(String(localized: "event_sleep"))
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                    }
                    .frame(maxWidth: .infinity)
                    .liquidGlassCard(backgroundColor: .indigo, cornerRadius: 18)
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

    private var noChildSelectedView: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.2), Color.purple.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 140, height: 140)
                    .blur(radius: 40)

                Image(systemName: "person.crop.circle.badge.plus")
                    .font(.system(size: 80))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .accessibilityHidden(true)
            }

            Text(String(localized: "dashboard_no_child_title"))
                .font(.title2)
                .fontWeight(.bold)

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
            }
            .liquidGlassButton(color: .blue, isPressed: false)
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

    private func reloadIfNeeded() {
        guard let childId = childProfileViewModel.selectedChild?.id else { return }
        loadDataForChild(childId)
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
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [color.opacity(0.3), color.opacity(0.15)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)
                        .shadow(color: color.opacity(0.3), radius: 8, x: 0, y: 4)

                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [color, color.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .accessibilityHidden(true)
                }

                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .liquidGlassCard(backgroundColor: color, cornerRadius: 18)
        }
        .buttonAccessibility(
            label: String(format: NSLocalizedString("add", comment: ""), title),
            hint: nil
        )
        .ensureMinimumTouchTarget()
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
