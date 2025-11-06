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
                .navigationTitle("Отслеживание")
                .navigationBarTitleDisplayMode(.large)
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
            .fullScreenCover(isPresented: $showingFeedingList) {
                FeedingListView(viewModel: feedingViewModel, childViewModel: childProfileViewModel)
                    .environment(\.managedObjectContext, viewContext)
            }
            .fullScreenCover(isPresented: $showingSleepList) {
                SleepListView(viewModel: sleepViewModel, childViewModel: childProfileViewModel)
                    .environment(\.managedObjectContext, viewContext)
            }
            .fullScreenCover(isPresented: $showingDiaperList) {
                DiaperListView()
                    .environmentObject(childProfileViewModel)
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
            Text("Добавить событие")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 12) {
                TrackingButton(
                    title: "Кормление",
                    subtitle: "Грудное, бутылочка или прикорм",
                    icon: "fork.knife.circle.fill",
                    color: .green
                ) {
                    showingAddFeeding = true
                }

                TrackingButton(
                    title: "Сон",
                    subtitle: "Начать или добавить сессию сна",
                    icon: "moon.zzz.fill",
                    color: .indigo
                ) {
                    showingAddSleep = true
                }

                TrackingButton(
                    title: "Подгузник",
                    subtitle: "Мокрый, грязный или оба",
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
            Text("Последние события")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            if let childId = child.id {
                VStack(spacing: 12) {

                    if let lastFeeding = feedingViewModel.getFeedingsToday(for: childId).first {
                        LastEventCard(
                            title: "Кормление",
                            icon: "fork.knife.circle.fill",
                            color: .green,
                            subtitle: lastFeeding.feedingType ?? "",
                            time: formatTime(lastFeeding.timestamp),
                            action: { showingFeedingList = true }
                        )
                    }

                    let sleepStats = sleepViewModel.getStatistics(for: childId)
                    if sleepStats.todayCount > 0 {
                        LastEventCard(
                            title: "Сон",
                            icon: "moon.zzz.fill",
                            color: .indigo,
                            subtitle: sleepStats.isCurrentlySleeping ? "Сейчас спит" : "Завершен",
                            time: formatTimeSince(sleepStats.timeSinceLastSleep),
                            action: { showingSleepList = true }
                        )
                    }

                    if let lastDiaper = diaperViewModel.getEventsToday(for: childId).first {
                        LastEventCard(
                            title: "Подгузник",
                            icon: "drop.fill",
                            color: .blue,
                            subtitle: lastDiaper.diaperType ?? "",
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

            Text("Выберите ребенка")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Перейдите в настройки, чтобы добавить профиль ребенка")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
    }

    private func loadDataForChild(_ childId: UUID) {
        feedingViewModel.loadFeedingEvents(for: childId)
        sleepViewModel.loadSleepEvents(for: childId)
        diaperViewModel.loadDiaperEvents(for: childId)
    }

    private func formatTime(_ date: Date?) -> String {
        guard let date = date else { return "" }

        let formatter = DateFormatter()
        formatter.timeStyle = .short

        let interval = Date().timeIntervalSince(date)
        let minutes = Int(interval / 60)

        if minutes < 60 {
            return "\(minutes) мин. назад"
        } else {
            let hours = minutes / 60
            return "\(hours) ч. назад"
        }
    }

    private func formatTimeSince(_ minutes: Int?) -> String {
        guard let minutes = minutes else { return "Только что" }

        if minutes < 60 {
            return "\(minutes) мин. назад"
        } else {
            let hours = minutes / 60
            return "\(hours) ч. назад"
        }
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
        .accessibilityLabel("Добавить \(title.lowercased())")
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
        .accessibilityLabel("Посмотреть все \(title.lowercased())")
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
