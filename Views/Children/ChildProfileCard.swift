import SwiftUI

struct ChildProfileCard: View {

    let child: ChildProfile
    let isSelected: Bool
    let onTap: () -> Void

    @ObservedObject var viewModel: ChildProfileViewModel

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {

                if let photoData = child.photoData, let uiImage = UIImage(data: photoData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 60, height: 60)
                        .clipShape(Circle())
                } else {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                        .foregroundColor(.gray)
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
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
