import SwiftUI

struct FloatingActionButton: View {

    let icon: String
    let action: () -> Void
    let backgroundColor: Color

    init(
        icon: String = "plus",
        backgroundColor: Color = .blue,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.backgroundColor = backgroundColor
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            ZStack {
                // Glass circle with gradient
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                backgroundColor.opacity(0.8),
                                backgroundColor.opacity(0.6)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)
                    .background(
                        .ultraThinMaterial,
                        in: Circle()
                    )
                    .overlay(
                        Circle()
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.6),
                                        Color.white.opacity(0.2)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )
                    .shadow(color: backgroundColor.opacity(0.4), radius: 15, x: 0, y: 8)
                    .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 2)

                Image(systemName: icon)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, .white.opacity(0.9)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
        }
        .accessibilityLabel(String(localized: "add"))
    }
}

#Preview {
    ZStack {
        Color(.systemGroupedBackground)
            .ignoresSafeArea()

        VStack {
            Spacer()
            HStack {
                Spacer()
                FloatingActionButton(action: {})
                    .padding()
            }
        }
    }
}
