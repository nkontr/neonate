import SwiftUI

struct BiometricSetupView: View {

    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss

    @State private var isSetupComplete: Bool = false

    var body: some View {
        VStack(spacing: 30) {
            Spacer()

            biometricIcon

            headerView

            benefitsView

            Spacer()

            actionButtons
        }
        .padding(.horizontal, 30)
        .padding(.vertical, 40)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
        .onChange(of: authViewModel.isBiometricEnabled) { _, isEnabled in
            if isEnabled {
                authViewModel.clearSuccess()
                dismiss()
            }
        }
        .alert(String(localized: "error"), isPresented: $authViewModel.showError) {
            Button(String(localized: "ok")) {
                authViewModel.clearError()
            }
        } message: {
            if let errorMessage = authViewModel.errorMessage {
                Text(errorMessage)
            }
        }
    }

    private var biometricIcon: some View {
        ZStack {
            Circle()
                .fill(Color.blue.opacity(0.1))
                .frame(width: 120, height: 120)

            Image(systemName: authViewModel.biometricIcon)
                .font(.system(size: 60))
                .foregroundColor(.blue)
        }
    }

    private var headerView: some View {
        VStack(spacing: 12) {
            Text(String(format: NSLocalizedString("biometric_setup", comment: ""), authViewModel.biometricDisplayName))
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            Text(String(localized: "biometric_fast_secure"))
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var benefitsView: some View {
        VStack(alignment: .leading, spacing: 20) {
            BenefitRow(
                icon: "lock.shield.fill",
                title: String(localized: "biometric_security_title"),
                description: String(localized: "biometric_security_desc")
            )

            BenefitRow(
                icon: "bolt.fill",
                title: String(localized: "biometric_fast_login_title"),
                description: String(localized: "biometric_fast_login_desc")
            )

            BenefitRow(
                icon: "hand.raised.fill",
                title: String(localized: "biometric_convenience_title"),
                description: String(localized: "biometric_convenience_desc")
            )
        }
    }

    private var actionButtons: some View {
        VStack(spacing: 15) {

            Button(action: handleEnableBiometric) {
                if authViewModel.isBiometricLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .frame(maxWidth: .infinity)
                        .padding()
                } else {
                    Text(String(format: NSLocalizedString("biometric_enable_button", comment: ""), authViewModel.biometricDisplayName))
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
            }
            .background(Color.blue)
            .cornerRadius(12)
            .disabled(authViewModel.isBiometricLoading)

            Button(action: { dismiss() }) {
                Text(String(localized: "biometric_setup_later"))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }

    private func handleEnableBiometric() {
        Task {
            await authViewModel.enableBiometric()
        }
    }
}

private struct BenefitRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)

                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}

#if Preview
struct BiometricSetupView_Previews: PreviewProvider {
    static var previews: some View {
        BiometricSetupView()
            .environmentObject(AuthViewModel.preview)
    }
}
#endif
