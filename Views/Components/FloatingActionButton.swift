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
            Image(systemName: icon)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(backgroundColor)
                .clipShape(Circle())
                .shadow(color: backgroundColor.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .accessibilityLabel("Добавить")
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
