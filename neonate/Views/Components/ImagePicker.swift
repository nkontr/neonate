import SwiftUI

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    var sourceType: UIImagePickerController.SourceType
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.allowsEditing = true

        // Check availability
        if UIImagePickerController.isSourceTypeAvailable(sourceType) {
            picker.sourceType = sourceType
        } else {
            picker.sourceType = .photoLibrary
        }

        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            var selectedImage: UIImage?

            if let editedImage = info[.editedImage] as? UIImage {
                selectedImage = editedImage
            } else if let originalImage = info[.originalImage] as? UIImage {
                selectedImage = originalImage
            }

            // Crop to circle
            if let image = selectedImage {
                parent.image = cropToCircle(image: image)
            }

            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }

        private func cropToCircle(image: UIImage) -> UIImage {
            let size: CGFloat = 500
            let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))

            let croppedImage = renderer.image { context in
                let rect = CGRect(x: 0, y: 0, width: size, height: size)
                UIBezierPath(ovalIn: rect).addClip()

                let imageSize = image.size
                let scale = max(size / imageSize.width, size / imageSize.height)
                let scaledWidth = imageSize.width * scale
                let scaledHeight = imageSize.height * scale

                let xOffset = (size - scaledWidth) / 2
                let yOffset = (size - scaledHeight) / 2

                image.draw(in: CGRect(
                    x: xOffset,
                    y: yOffset,
                    width: scaledWidth,
                    height: scaledHeight
                ))
            }

            return croppedImage
        }
    }
}
