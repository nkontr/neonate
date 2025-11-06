import SwiftUI

struct LoadingView: View {

    var message: String?

    var showBackground: Bool = true

    var body: some View {
        ZStack {
            if showBackground {
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.2)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            }

            VStack(spacing: 20) {
                Image(systemName: "heart.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)

                Text("neonate")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)

                if let message = message {
                    Text(message)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                    .scaleEffect(1.2)
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
