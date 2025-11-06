import SwiftUI
import CoreData

struct SettingsView: View {

    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var childProfileViewModel: ChildProfileViewModel

    @State private var showingChildrenList = false
    @State private var showingLogoutAlert = false
    @State private var notificationsEnabled = false
    @AppStorage("appTheme") private var appTheme: AppTheme = .system

    var body: some View {
        NavigationView {
            List {

                userProfileSection

                childrenSection

                notificationsSection

                appSettingsSection

                aboutSection

                logoutSection
            }
            .listStyle(.insetGrouped)
            .navigationTitle(String(localized: "settings_title"))
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingChildrenList) {
                ChildrenListView(viewModel: childProfileViewModel)
                    .environment(\.managedObjectContext, viewContext)
            }
            .alert(String(localized: "settings_logout_title"), isPresented: $showingLogoutAlert) {
                Button(String(localized: "cancel"), role: .cancel) {}
                Button(String(localized: "settings_logout"), role: .destructive) {
                    Task {
                        await authViewModel.logout()
                    }
                }
            } message: {
                Text(String(localized: "settings_logout_message"))
            }
        }
    }

    private var userProfileSection: some View {
        Section {
            HStack {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 4) {
                    Text(authViewModel.currentUser?.username ?? String(localized: "settings_user_profile"))
                        .font(.headline)

                    Text(authViewModel.currentUser?.email ?? "")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 8)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(authViewModel.currentUser?.username ?? String(localized: "settings_user_profile")), \(authViewModel.currentUser?.email ?? "")")
        }
    }

    private var childrenSection: some View {
        Section(String(localized: "settings_children")) {
            Button {
                showingChildrenList = true
            } label: {
                HStack {
                    Image(systemName: "person.2.fill")
                        .foregroundColor(.blue)
                        .accessibilityHidden(true)

                    Text(String(localized: "settings_manage_children"))

                    Spacer()

                    Text("\(childProfileViewModel.children.count)")
                        .foregroundColor(.secondary)

                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                        .font(.caption)
                        .accessibilityHidden(true)
                }
            }
            .foregroundColor(.primary)
            .navigationAccessibility(
                destination: String(localized: "settings_children"),
                label: "\(String(localized: "settings_manage_children")), \(childProfileViewModel.children.count) \(String(localized: "children_count"))"
            )
        }
    }

    private var notificationsSection: some View {
        Section {
            NavigationLink {
                RemindersListView(context: viewContext)
                    .environmentObject(childProfileViewModel)
            } label: {
                HStack {
                    Image(systemName: "clock.fill")
                        .foregroundColor(.purple)
                        .accessibilityHidden(true)

                    Text(String(localized: "settings_reminders"))

                    Spacer()

                    if let selectedChild = childProfileViewModel.selectedChild {
                        let remindersCount = ReminderManager.shared.fetchActiveReminders(for: selectedChild.id!).count
                        if remindersCount > 0 {
                            Text("\(remindersCount)")
                                .foregroundColor(.secondary)
                                .font(.subheadline)
                                .accessibilityLabel(String.localizedStringWithFormat(NSLocalizedString("reminders_count", comment: ""), remindersCount))
                        }
                    }
                }
            }
        } header: {
            Text(String(localized: "settings_notifications"))
        } footer: {
            Text(String(localized: "reminders_empty_message"))
        }
    }

    private var appSettingsSection: some View {
        Section(String(localized: "settings_app")) {
            Picker(selection: $appTheme) {
                ForEach(AppTheme.allCases) { theme in
                    HStack {
                        Image(systemName: theme.icon)
                            .accessibilityHidden(true)
                        Text(theme.displayName)
                    }
                    .tag(theme)
                }
            } label: {
                HStack {
                    Image(systemName: "paintbrush.fill")
                        .foregroundColor(.pink)
                        .accessibilityHidden(true)

                    Text(String(localized: "settings_theme"))
                }
            }
            .accessibilityLabel(String(localized: "settings_theme"))
            .accessibilityValue(appTheme.displayName)

            Toggle(isOn: .constant(authViewModel.isBiometricEnabled)) {
                HStack {
                    Image(systemName: authViewModel.biometricIcon)
                        .foregroundColor(.green)
                        .accessibilityHidden(true)

                    Text(authViewModel.biometricDisplayName)
                }
            }
            .disabled(!authViewModel.isBiometricAvailable)
            .onChange(of: authViewModel.isBiometricEnabled) { _ in
                Task {
                    await authViewModel.toggleBiometric()
                }
            }
            .toggleAccessibility(
                label: authViewModel.biometricDisplayName,
                isOn: authViewModel.isBiometricEnabled
            )
        }
    }

    private var aboutSection: some View {
        Section(String(localized: "settings_about")) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.blue)
                    .accessibilityHidden(true)

                Text(String(localized: "settings_version"))

                Spacer()

                Text("1.0.0")
                    .foregroundColor(.secondary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(String(localized: "settings_version")): 1.0.0")

            NavigationLink {
                PrivacyPolicyView()
            } label: {
                HStack {
                    Image(systemName: "hand.raised.fill")
                        .foregroundColor(.blue)
                        .accessibilityHidden(true)

                    Text(String(localized: "settings_privacy_policy"))
                }
            }

            NavigationLink {
                TermsOfServiceView()
            } label: {
                HStack {
                    Image(systemName: "doc.text.fill")
                        .foregroundColor(.blue)
                        .accessibilityHidden(true)

                    Text(String(localized: "settings_terms_of_service"))
                }
            }
        }
    }

    private var logoutSection: some View {
        Section {
            Button {
                showingLogoutAlert = true
            } label: {
                HStack {
                    Spacer()

                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .foregroundColor(.red)
                        .accessibilityHidden(true)

                    Text(String(localized: "settings_logout"))
                        .foregroundColor(.red)
                        .fontWeight(.semibold)

                    Spacer()
                }
            }
            .buttonAccessibility(
                label: String(localized: "settings_logout"),
                hint: String(localized: "settings_logout_message")
            )
        }
    }
}

enum AppTheme: String, CaseIterable, Identifiable {
    case system = "system"
    case light = "light"
    case dark = "dark"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .system:
            return String(localized: "settings_theme_system")
        case .light:
            return String(localized: "settings_theme_light")
        case .dark:
            return String(localized: "settings_theme_dark")
        }
    }

    var icon: String {
        switch self {
        case .system:
            return "circle.lefthalf.filled"
        case .light:
            return "sun.max.fill"
        case .dark:
            return "moon.fill"
        }
    }
}

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(String(localized: "privacy_policy_title"))
                    .font(.title)
                    .fontWeight(.bold)

                Text(String(localized: "privacy_policy_updated"))
                    .font(.caption)
                    .foregroundColor(.secondary)

                Divider()

                Text(String(localized: "privacy_policy_intro"))
                    .font(.body)

                Text(String(localized: "privacy_policy_data_storage"))
                    .font(.body)

                Spacer()
            }
            .padding()
        }
        .navigationTitle(String(localized: "privacy_policy_title"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct TermsOfServiceView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(String(localized: "terms_title"))
                    .font(.title)
                    .fontWeight(.bold)

                Text(String(localized: "terms_updated"))
                    .font(.caption)
                    .foregroundColor(.secondary)

                Divider()

                Text(String(localized: "terms_intro"))
                    .font(.body)

                Text(String(localized: "terms_disclaimer"))
                    .font(.body)

                Spacer()
            }
            .padding()
        }
        .navigationTitle(String(localized: "terms_title"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

#if DEBUG
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(AuthViewModel.preview)
            .environmentObject(ChildProfileViewModel(context: PersistenceController.preview.container.viewContext))
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
#endif
