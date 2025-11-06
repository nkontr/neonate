import SwiftUI
import CoreData

struct AnalyticsView: View {

    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var childProfileViewModel: ChildProfileViewModel

    @StateObject private var analyticsViewModel: AnalyticsViewModel

    @State private var isFirstAppear = true

    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        _analyticsViewModel = StateObject(wrappedValue: AnalyticsViewModel(context: context))
    }

    var body: some View {
        NavigationView {
            ZStack {
                if analyticsViewModel.isLoading && isFirstAppear {

                    loadingView
                } else if let errorMessage = analyticsViewModel.errorMessage {

                    errorView(message: errorMessage)
                } else if childProfileViewModel.selectedChild == nil {

                    noChildView
                } else {

                    contentView
                }
            }
            .navigationTitle("Аналитика")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    refreshButton
                }
            }
            .onAppear {
                loadAnalyticsIfNeeded()
            }
            .onChange(of: childProfileViewModel.selectedChild?.id) { newId in
                if let childId = newId {
                    analyticsViewModel.loadAnalyticsData(for: childId)
                }
            }
            .onChange(of: analyticsViewModel.selectedPeriod) { _ in

            }
        }
    }

    private var contentView: some View {
        ScrollView {
            VStack(spacing: 20) {

                PeriodPicker(selectedPeriod: $analyticsViewModel.selectedPeriod)
                    .padding(.top)

                if !analyticsViewModel.isLoading {
                    summaryCards
                }

                analyticsCards
                    .opacity(analyticsViewModel.isLoading && !isFirstAppear ? 0.5 : 1.0)
            }
            .padding(.bottom, 20)
        }
        .refreshable {
            analyticsViewModel.refreshAnalytics()
        }
    }

    private var summaryCards: some View {
        HStack(spacing: 12) {

            SummaryCard(
                icon: "fork.knife",
                title: "Кормлений/день",
                value: String(format: "%.1f", analyticsViewModel.getAverageFeedingsPerDay()),
                color: .blue
            )

            SummaryCard(
                icon: "moon.fill",
                title: "Сна/день",
                value: String(format: "%.1fч", analyticsViewModel.getAverageSleepPerDay()),
                color: .purple
            )

            SummaryCard(
                icon: "leaf.fill",
                title: "Смен/день",
                value: String(format: "%.1f", analyticsViewModel.getAverageDiaperChangesPerDay()),
                color: .green
            )
        }
        .padding(.horizontal)
    }

    private var analyticsCards: some View {
        VStack(spacing: 16) {

            if let feedingAnalytics = analyticsViewModel.feedingAnalytics {
                FeedingAnalyticsCard(
                    analytics: feedingAnalytics,
                    period: analyticsViewModel.selectedPeriod
                )
                .padding(.horizontal)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            if let sleepAnalytics = analyticsViewModel.sleepAnalytics {
                SleepAnalyticsCard(
                    analytics: sleepAnalytics,
                    period: analyticsViewModel.selectedPeriod
                )
                .padding(.horizontal)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            if let diaperAnalytics = analyticsViewModel.diaperAnalytics {
                DiaperAnalyticsCard(
                    analytics: diaperAnalytics,
                    period: analyticsViewModel.selectedPeriod
                )
                .padding(.horizontal)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeInOut, value: analyticsViewModel.isLoading)
    }

    private var loadingView: some View {
        VStack(spacing: 20) {
            PeriodPicker(selectedPeriod: $analyticsViewModel.selectedPeriod)
                .padding(.top)
                .padding(.horizontal)

            VStack(spacing: 16) {
                ForEach(0..<3) { _ in
                    ShimmerCard()
                        .padding(.horizontal)
                }
            }

            Spacer()
        }
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(.orange)

            Text("Ошибка загрузки")
                .font(.title2)
                .fontWeight(.bold)

            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button {
                analyticsViewModel.refreshAnalytics()
            } label: {
                Label("Повторить", systemImage: "arrow.clockwise")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
        }
        .padding()
    }

    private var noChildView: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.crop.circle.badge.questionmark")
                .font(.system(size: 80))
                .foregroundColor(.gray)

            Text("Выберите ребенка")
                .font(.title2)
                .fontWeight(.bold)

            Text("Для просмотра аналитики необходимо выбрать профиль ребенка")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
    }

    private var refreshButton: some View {
        Button {
            analyticsViewModel.refreshAnalytics()
        } label: {
            Image(systemName: "arrow.clockwise")
                .imageScale(.large)
        }
        .disabled(analyticsViewModel.isLoading)
    }

    private func loadAnalyticsIfNeeded() {
        guard let childId = childProfileViewModel.selectedChild?.id else { return }

        if isFirstAppear {
            analyticsViewModel.loadAnalyticsData(for: childId)
            isFirstAppear = false
        }
    }
}

struct SummaryCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.primary)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }
}

struct ShimmerCard: View {
    @State private var isAnimating = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {

            HStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 120, height: 20)

                Spacer()

                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 60, height: 28)
            }

            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.3))
                .frame(height: 200)

            VStack(spacing: 8) {
                ForEach(0..<3) { _ in
                    HStack {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 150, height: 16)

                        Spacer()

                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 80, height: 16)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        .overlay(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.clear,
                    Color.white.opacity(0.3),
                    Color.clear
                ]),
                startPoint: .leading,
                endPoint: .trailing
            )
            .offset(x: isAnimating ? 400 : -400)
        )
        .onAppear {
            withAnimation(Animation.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                isAnimating = true
            }
        }
    }
}

#if DEBUG
struct AnalyticsView_Previews: PreviewProvider {
    static var previews: some View {
        AnalyticsView(context: PersistenceController.preview.container.viewContext)
            .environmentObject(ChildProfileViewModel())
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
#endif
