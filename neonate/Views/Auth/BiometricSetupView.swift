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
        .alert("Успех", isPresented: $authViewModel.showSuccess) {
            Button("OK") {
                authViewModel.clearSuccess()
                isSetupComplete = true
                dismiss()
            }
        } message: {
            if let successMessage = authViewModel.successMessage {
                Text(successMessage)
            }
        }
        .alert("Ошибка", isPresented: $authViewModel.showError) {
            Button("OK") {
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
            Text("Настроить \(authViewModel.biometricDisplayName)")
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            Text("Быстрый и безопасный вход в приложение")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var benefitsView: some View {
        VStack(alignment: .leading, spacing: 20) {
            BenefitRow(
                icon: "lock.shield.fill",
                title: "Безопасность",
                description: "Ваши данные надежно защищены"
            )

            BenefitRow(
                icon: "bolt.fill",
                title: "Быстрый вход",
                description: "Входите в приложение мгновенно"
            )

            BenefitRow(
                icon: "hand.raised.fill",
                title: "Удобство",
                description: "Не нужно запоминать пароль"
            )
        }
    }

    private var actionButtons: some View {
        VStack(spacing: 15) {

            Button(action: handleEnableBiometric) {
                if authViewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .frame(maxWidth: .infinity)
                        .padding()
                } else {
                    Text("Включить \(authViewModel.biometricDisplayName)")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
            }
            .background(Color.blue)
            .cornerRadius(12)
            .disabled(authViewModel.isLoading)

            Button(action: { dismiss() }) {
                Text("Настроить позже")
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
