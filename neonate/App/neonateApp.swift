import SwiftUI
import UserNotifications

@main
struct neonateApp: App {

    let persistenceController = PersistenceController.shared

    @StateObject private var authViewModel = AuthViewModel()

    init() {
        UNUserNotificationCenter.current().delegate = NotificationService.shared

        // ВРЕМЕННО: Сброс для тестирования onboarding
        UserDefaults.standard.removeObject(forKey: "appInstallDate")
        UserDefaults.standard.removeObject(forKey: "hasSeenOnboarding")
        UserDefaults.standard.removeObject(forKey: "hasLaunchedBefore")
        print("🔄 RESET: All onboarding flags cleared")

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
        // Проверяем, установлен ли маркер установки приложения
        let appInstallDate = UserDefaults.standard.object(forKey: "appInstallDate") as? Date

        if appInstallDate == nil {
            // Это первая установка приложения
            print("🆕 First install detected - resetting all data")
            try? KeychainService.shared.clearAll()
            UserDefaults.standard.set(Date(), forKey: "appInstallDate")
            UserDefaults.standard.set(false, forKey: "hasSeenOnboarding")
            UserDefaults.standard.removeObject(forKey: "hasShownBiometricSetup")
            UserDefaults.standard.removeObject(forKey: "hasLaunchedBefore")
            print("✅ All data reset for first install")
        } else {
            print("📱 App was installed on: \(appInstallDate!)")
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
        ZStack {
            if authViewModel.isLoading {
                LoadingView()
            } else if !hasSeenOnboarding && !authViewModel.isAuthenticated {
                OnboardingView()
                    .onDisappear {
                        hasSeenOnboarding = true
                    }
            } else if authViewModel.isAuthenticated {
                if requiresBiometricAuth {
                    BiometricAuthView()
                        .environmentObject(authViewModel)
                        .onAppear {
                            authenticateWithBiometric()
                        }
                } else {
                    MainAppView()
                }
            } else {
                LoginView()
            }
        }
        .onAppear {
            print("📱 RootView appeared")
            print("📱 hasSeenOnboarding: \(hasSeenOnboarding)")
            print("📱 isLoading: \(authViewModel.isLoading)")
            print("📱 isAuthenticated: \(authViewModel.isAuthenticated)")

            if authViewModel.isLoading {
                print("🎯 Should show LoadingView")
            } else if !hasSeenOnboarding && !authViewModel.isAuthenticated {
                print("🎯 Should show OnboardingView")
            } else if authViewModel.isAuthenticated {
                print("🎯 Should show MainAppView")
            } else {
                print("🎯 Should show LoginView")
            }
        }
        .preferredColorScheme(appTheme.colorScheme)
        .onChange(of: authViewModel.isLoading) { oldValue, newValue in
            print("⚡️ isLoading changed: \(oldValue) -> \(newValue)")
        }
        .onChange(of: authViewModel.isAuthenticated) { oldValue, newValue in
            print("⚡️ isAuthenticated changed: \(oldValue) -> \(newValue)")
            if newValue && authViewModel.isBiometricEnabled && !hasCheckedBiometric {
                requiresBiometricAuth = true
            } else if !newValue {
                requiresBiometricAuth = false
                hasCheckedBiometric = false
            }
        }
        .onChange(of: hasSeenOnboarding) { oldValue, newValue in
            print("⚡️ hasSeenOnboarding changed: \(oldValue) -> \(newValue)")
        }
        .task {
            // Проверяем авторизацию только если уже видели onboarding
            if hasSeenOnboarding {
                print("🔐 Checking authentication status...")
                await authViewModel.checkAuthenticationStatus()
            } else {
                print("👋 First launch - skipping auth check")
            }

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
