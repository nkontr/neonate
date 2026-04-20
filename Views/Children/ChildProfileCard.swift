import SwiftUI

struct ChildProfileCard: View {

    let child: ChildProfile
    let isSelected: Bool
    let onTap: () -> Void

    @ObservedObject var viewModel: ChildProfileViewModel

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {

                ZStack {
                    if let photoData = child.photoData, let uiImage = UIImage(data: photoData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 60, height: 60)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .strokeBorder(
                                        LinearGradient(
                                            colors: [.white.opacity(0.5), .clear],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 2
                                    )
                            )
                    } else {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 60, height: 60)
                            .overlay(
                                Image(systemName: "person.circle.fill")
                                    .font(.system(size: 40))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.blue, .purple],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            )
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(child.name ?? "Без имени")
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text(viewModel.getFormattedAge(for: child))
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    if let gender = child.gender {
                        Text(gender)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title2)
                }
            }
            .liquidGlassCard(
                backgroundColor: isSelected ? .blue : .gray,
                cornerRadius: 20,
                glowColor: isSelected ? .blue : nil
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
