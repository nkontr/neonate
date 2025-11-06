import SwiftUI
import UserNotifications

@main
struct neonateApp: App {

    let persistenceController = PersistenceController.shared

    @StateObject private var authViewModel = AuthViewModel()
    init() {
        UNUserNotificationCenter.current().delegate = NotificationService.shared
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(authViewModel)
                .onAppear {
                    NotificationService.shared.clearBadge()
                }
        }
    }
}

struct RootView: View {

    @EnvironmentObject var authViewModel: AuthViewModel

    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding: Bool = false

    var body: some View {
        Group {
            if authViewModel.isLoading {
                LoadingView()
            } else if authViewModel.isAuthenticated {
                MainAppView()
                    .onAppear {
                        if !hasSeenOnboarding {
                            hasSeenOnboarding = true
                        }
                    }
            } else if !hasSeenOnboarding {
                OnboardingView()
                    .onDisappear {
                        hasSeenOnboarding = true
                    }
            } else {
                LoginView()
            }
        }
        .animation(.easeInOut, value: authViewModel.isAuthenticated)
        .animation(.easeInOut, value: authViewModel.isLoading)
        .onChange(of: authViewModel.isAuthenticated) { newValue in
            print("🔐 Authentication status changed: \(newValue)")
        }
    }
}

struct MainAppView: View {

    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var authViewModel: AuthViewModel

    @State private var showBiometricSetup: Bool = false
    @State private var hasCheckedBiometricSetup: Bool = false

    var body: some View {
        MainTabView(context: viewContext)
            .environmentObject(authViewModel)
            .onAppear {
                checkBiometricSetup()
            }
            .sheet(isPresented: $showBiometricSetup) {
                BiometricSetupView()
                    .environmentObject(authViewModel)
            }
    }

    private func checkBiometricSetup() {
        guard !hasCheckedBiometricSetup else { return }
        hasCheckedBiometricSetup = true

        if authViewModel.isBiometricAvailable && !authViewModel.isBiometricEnabled {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                showBiometricSetup = true
            }
        }
    }
}

#if Preview
struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        Group {

            RootView()
                .environmentObject(AuthViewModel.preview)
                .previewDisplayName("Authenticated")

            RootView()
                .environmentObject(AuthViewModel.previewUnauthenticated)
                .previewDisplayName("Not Authenticated")

            RootView()
                .environmentObject(AuthViewModel.previewLoading)
                .previewDisplayName("Loading")
        }
    }
}
#endif
