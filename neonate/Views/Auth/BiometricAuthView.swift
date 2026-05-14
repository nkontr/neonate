import SwiftUI

struct BiometricAuthView: View {

    @EnvironmentObject var authViewModel: AuthViewModel
    var onRetry: (() -> Void)? = nil

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()

                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 150, height: 150)
                        .blur(radius: 20)

                    Circle()
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 120, height: 120)

                    Image(systemName: authViewModel.biometricIcon)
                        .font(.system(size: 60))
                        .foregroundColor(.white)
                }

                VStack(spacing: 16) {
                    Text(String(format: NSLocalizedString("biometric_unlock_title", comment: ""), authViewModel.biometricDisplayName))
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)

                    Text(String(localized: "biometric_unlock_message"))
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }

                Spacer()

                if authViewModel.isLoading && !authViewModel.showError {
                    // Show loading indicator while authenticating
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                        .frame(height: 60)
                } else if authViewModel.showError {
                    VStack(spacing: 12) {
                        Text(authViewModel.errorMessage ?? String(localized: "biometric_auth_failed"))
                            .font(.subheadline)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        VStack(spacing: 12) {
                            Button {
                                authViewModel.clearError()
                                if let onRetry = onRetry {
                                    onRetry()
                                } else {
                                    Task {
                                        await authViewModel.loginWithBiometric()
                                    }
                                }
                            } label: {
                                Text(String(localized: "retry"))
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .cornerRadius(12)
                            }
                            .disabled(authViewModel.isLoading)

                            Button {
                                Task {
                                    await authViewModel.logout()
                                }
                            } label: {
                                Text(String(localized: "logout"))
                                    .font(.headline)
                                    .foregroundColor(.red)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.white.opacity(0.2))
                                    .cornerRadius(12)
                            }
                            .disabled(authViewModel.isLoading)
                        }
                        .padding(.horizontal, 40)
                    }
                }

                Spacer()
            }
        }
    }
}

#if Preview
struct BiometricAuthView_Previews: PreviewProvider {
    static var previews: some View {
        BiometricAuthView()
            .environmentObject(AuthViewModel.preview)
    }
}
#endif
