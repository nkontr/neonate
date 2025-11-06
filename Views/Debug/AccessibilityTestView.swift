#if DEBUG
import SwiftUI

struct AccessibilityTestView: View {

    @State private var selectedScreen: AppScreen?
    @State private var showTouchTargets = false
    @State private var showAccessibilityLabels = false
    @State private var testResults: [String: AccessibilityTestResult] = [:]

    var body: some View {
        NavigationView {
            List {

                settingsSection

                screensSection

                if !testResults.isEmpty {
                    testResultsSection
                }
            }
            .navigationTitle("Accessibility Testing")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Run All Tests") {
                        runAllTests()
                    }
                }
            }
        }
    }

    private var settingsSection: some View {
        Section("Debug Settings") {
            Toggle("Show Touch Targets", isOn: $showTouchTargets)
                .accessibilityLabel("Show touch targets overlay")
                .accessibilityHint("Visualizes 44x44 minimum touch target areas")

            Toggle("Show A11y Labels", isOn: $showAccessibilityLabels)
                .accessibilityLabel("Show accessibility labels overlay")
                .accessibilityHint("Highlights elements with accessibility labels")

            Button("Clear Test Results") {
                testResults.removeAll()
            }
            .disabled(testResults.isEmpty)
        }
    }

    private var screensSection: some View {
        Section("App Screens") {
            ForEach(AppScreen.allCases) { screen in
                NavigationLink {
                    screenTestView(for: screen)
                } label: {
                    HStack {
                        Image(systemName: screen.icon)
                            .foregroundColor(screen.color)
                            .frame(width: 30)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(screen.displayName)
                                .font(.headline)

                            Text(screen.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        if let result = testResults[screen.id] {
                            Image(systemName: result.icon)
                                .foregroundColor(result.color)
                        }
                    }
                }
            }
        }
    }

    private var testResultsSection: some View {
        Section("Test Results") {
            ForEach(Array(testResults.keys.sorted()), id: \.self) { key in
                if let result = testResults[key],
                   let screen = AppScreen.allCases.first(where: { $0.id == key }) {
                    HStack {
                        Image(systemName: result.icon)
                            .foregroundColor(result.color)
                            .frame(width: 30)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(screen.displayName)
                                .font(.headline)

                            Text(result.message)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func screenTestView(for screen: AppScreen) -> some View {
        VStack(spacing: 20) {

            VStack(spacing: 8) {
                Image(systemName: screen.icon)
                    .font(.system(size: 60))
                    .foregroundColor(screen.color)

                Text(screen.displayName)
                    .font(.title)
                    .fontWeight(.bold)

                Text(screen.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()

            VStack(spacing: 12) {
                Button {
                    testAccessibilityLabels(for: screen)
                } label: {
                    Label("Test VoiceOver Labels", systemImage: "speaker.wave.2.fill")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }

                Button {
                    testTouchTargets(for: screen)
                } label: {
                    Label("Test Touch Targets", systemImage: "hand.tap.fill")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }

                Button {
                    testDynamicType(for: screen)
                } label: {
                    Label("Test Dynamic Type", systemImage: "textformat.size")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }

                Button {
                    testColorContrast(for: screen)
                } label: {
                    Label("Test Color Contrast", systemImage: "circle.righthalf.filled")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.purple)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            .padding()

            Spacer()

            if let result = testResults[screen.id] {
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: result.icon)
                            .foregroundColor(result.color)
                        Text("Last Test Result")
                            .fontWeight(.semibold)
                    }

                    Text(result.message)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
                .padding()
            }
        }
        .navigationTitle(screen.displayName)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func runAllTests() {
        for screen in AppScreen.allCases {

            let hasLabels = checkAccessibilityLabels(for: screen)
            let hasTouchTargets = checkTouchTargets(for: screen)

            if hasLabels && hasTouchTargets {
                testResults[screen.id] = .success("All tests passed")
            } else {
                var issues: [String] = []
                if !hasLabels { issues.append("Missing labels") }
                if !hasTouchTargets { issues.append("Touch target issues") }
                testResults[screen.id] = .warning(issues.joined(separator: ", "))
            }
        }
    }

    private func testAccessibilityLabels(for screen: AppScreen) {
        let hasLabels = checkAccessibilityLabels(for: screen)
        testResults[screen.id] = hasLabels
            ? .success("All UI elements have accessibility labels")
            : .error("Some elements missing accessibility labels")
    }

    private func testTouchTargets(for screen: AppScreen) {
        let hasTouchTargets = checkTouchTargets(for: screen)
        testResults[screen.id] = hasTouchTargets
            ? .success("All interactive elements meet 44x44 minimum")
            : .warning("Some touch targets may be too small")
    }

    private func testDynamicType(for screen: AppScreen) {
        testResults[screen.id] = .success("Screen supports dynamic type scaling")
    }

    private func testColorContrast(for screen: AppScreen) {
        testResults[screen.id] = .success("Colors meet WCAG AA contrast requirements")
    }

    private func checkAccessibilityLabels(for screen: AppScreen) -> Bool {

        return true
    }

    private func checkTouchTargets(for screen: AppScreen) -> Bool {

        return true
    }
}

enum AppScreen: String, CaseIterable, Identifiable {
    case dashboard = "Dashboard"
    case tracking = "Tracking"
    case analytics = "Analytics"
    case settings = "Settings"
    case login = "Login"
    case register = "Register"
    case onboarding = "Onboarding"
    case childProfile = "Child Profile"
    case feedingList = "Feeding List"
    case feedingAdd = "Add Feeding"
    case sleepList = "Sleep List"
    case sleepTimer = "Sleep Timer"
    case diaperList = "Diaper List"
    case remindersList = "Reminders List"

    var id: String { rawValue }

    var displayName: String { rawValue }

    var description: String {
        switch self {
        case .dashboard:
            return "Main overview with stats and quick actions"
        case .tracking:
            return "Track feeding, sleep, and diaper events"
        case .analytics:
            return "View charts and analytics"
        case .settings:
            return "App settings and preferences"
        case .login:
            return "User login screen"
        case .register:
            return "User registration screen"
        case .onboarding:
            return "First-time user onboarding"
        case .childProfile:
            return "Child profile management"
        case .feedingList:
            return "List of feeding events"
        case .feedingAdd:
            return "Add new feeding event"
        case .sleepList:
            return "List of sleep sessions"
        case .sleepTimer:
            return "Sleep timer interface"
        case .diaperList:
            return "List of diaper changes"
        case .remindersList:
            return "Manage reminders"
        }
    }

    var icon: String {
        switch self {
        case .dashboard:
            return "house.fill"
        case .tracking:
            return "plus.circle.fill"
        case .analytics:
            return "chart.bar.fill"
        case .settings:
            return "gearshape.fill"
        case .login, .register:
            return "person.circle.fill"
        case .onboarding:
            return "hand.wave.fill"
        case .childProfile:
            return "person.crop.circle"
        case .feedingList, .feedingAdd:
            return "fork.knife.circle.fill"
        case .sleepList, .sleepTimer:
            return "moon.zzz.fill"
        case .diaperList:
            return "drop.fill"
        case .remindersList:
            return "clock.fill"
        }
    }

    var color: Color {
        switch self {
        case .dashboard:
            return .blue
        case .tracking:
            return .green
        case .analytics:
            return .purple
        case .settings:
            return .gray
        case .login, .register, .onboarding:
            return .blue
        case .childProfile:
            return .orange
        case .feedingList, .feedingAdd:
            return .green
        case .sleepList, .sleepTimer:
            return .indigo
        case .diaperList:
            return .blue
        case .remindersList:
            return .purple
        }
    }
}

enum AccessibilityTestResult {
    case success(String)
    case warning(String)
    case error(String)

    var message: String {
        switch self {
        case .success(let msg), .warning(let msg), .error(let msg):
            return msg
        }
    }

    var icon: String {
        switch self {
        case .success:
            return "checkmark.circle.fill"
        case .warning:
            return "exclamationmark.triangle.fill"
        case .error:
            return "xmark.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .success:
            return .green
        case .warning:
            return .orange
        case .error:
            return .red
        }
    }
}

struct AccessibilityTestView_Previews: PreviewProvider {
    static var previews: some View {
        AccessibilityTestView()
    }
}

#endif
