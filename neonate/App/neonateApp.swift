import SwiftUI
import UserNotifications

@main
struct neonateApp: App {

    let persistenceController = PersistenceController.shared

    @StateObject private var authViewModel = AuthViewModel()

    init() {
        UNUserNotificationCenter.current().delegate = NotificationService.shared
        checkFirstLaunch()
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

    private func checkFirstLaunch() {
        let hasLaunchedBefore = UserDefaults.standard.bool(forKey: "hasLaunchedBefore")

        if !hasLaunchedBefore {
            Task {
                try? await KeychainService.shared.clearAll()
            }
            UserDefaults.standard.removeObject(forKey: "hasSeenOnboarding")
            UserDefaults.standard.removeObject(forKey: "hasShownBiometricSetup")
            UserDefaults.standard.set(true, forKey: "hasLaunchedBefore")
        }
    }
}

struct RootView: View {

    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.scenePhase) private var scenePhase

    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding: Bool = false
    @AppStorage("appTheme") private var appTheme: AppTheme = .system

    @State private var requiresBiometricAuth = false
    @State private var hasCheckedBiometric = false

    var body: some View {
        Group {
            if authViewModel.isLoading {
                LoadingView()
            } else if authViewModel.isAuthenticated {
                if requiresBiometricAuth {
                    BiometricAuthView()
                        .environmentObject(authViewModel)
                        .onAppear {
                            authenticateWithBiometric()
                        }
                } else {
                    MainAppView()
                        .onAppear {
                            if !hasSeenOnboarding {
                                hasSeenOnboarding = true
                            }
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
        .preferredColorScheme(appTheme.colorScheme)
        .onChange(of: authViewModel.isAuthenticated) { _, newValue in
            if newValue && authViewModel.isBiometricEnabled && !hasCheckedBiometric {
                requiresBiometricAuth = true
            } else if !newValue {
                requiresBiometricAuth = false
                hasCheckedBiometric = false
            }
        }
        .task {
            // Даём время для загрузки состояния
            try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 секунды

            if authViewModel.isAuthenticated && authViewModel.isBiometricEnabled && !hasCheckedBiometric {
                requiresBiometricAuth = true
            }
        }
    }

    private func authenticateWithBiometric() {
        Task {
            await authViewModel.loginWithBiometric()
            hasCheckedBiometric = true
            requiresBiometricAuth = false
        }
    }
}

struct MainAppView: View {

    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var authViewModel: AuthViewModel

    @State private var showBiometricSetup: Bool = false
    @State private var hasCheckedBiometricSetup: Bool = false
    @AppStorage("hasShownBiometricSetup") private var hasShownBiometricSetup: Bool = false

    var body: some View {
        MainTabView()
            .environmentObject(authViewModel)
            .onAppear {
                checkBiometricSetup()
            }
            .sheet(isPresented: $showBiometricSetup) {
                BiometricSetupView()
                    .environmentObject(authViewModel)
                    .onDisappear {
                        if authViewModel.isBiometricEnabled {
                            hasShownBiometricSetup = true
                        }
                    }
            }
    }

    private func checkBiometricSetup() {
        guard !hasCheckedBiometricSetup else { return }
        hasCheckedBiometricSetup = true

        if authViewModel.isBiometricAvailable && !authViewModel.isBiometricEnabled && !hasShownBiometricSetup {
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
