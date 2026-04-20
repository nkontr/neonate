import SwiftUI

struct LoadingView: View {

    var message: String?

    var showBackground: Bool = true

    var body: some View {
        ZStack {
            if showBackground {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.4, green: 0.6, blue: 1.0).opacity(0.4),
                        Color(red: 0.6, green: 0.4, blue: 0.9).opacity(0.3)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            }

            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.blue.opacity(0.3),
                                    Color.purple.opacity(0.2)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 140, height: 140)
                        .blur(radius: 40)

                    Image(systemName: "heart.circle.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }

                Text("neonate")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.primary, .primary.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )

                if let message = message {
                    Text(message)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                    .scaleEffect(1.3)
                    .padding(.top, 20)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(message ?? "Загрузка")
    }
}

struct MiniLoadingView: View {
    var body: some View {
        VStack(spacing: 12) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .blue))

            Text("Загрузка...")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

#if DEBUG
struct LoadingView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            LoadingView()
                .previewDisplayName("Стандартная загрузка")

            LoadingView(message: "Синхронизация данных...", showBackground: true)
                .previewDisplayName("С сообщением")

            LoadingView(message: "Сохранение...", showBackground: false)
                .previewDisplayName("Без фона")
                .preferredColorScheme(.dark)

            MiniLoadingView()
                .previewDisplayName("Компактная версия")
                .previewLayout(.sizeThatFits)
                .padding()
        }
    }
}
#endif
