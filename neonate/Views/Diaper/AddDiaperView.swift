import SwiftUI
import CoreData

struct AddDiaperView: View {

    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var childProfileViewModel: ChildProfileViewModel

    @StateObject private var viewModel: DiaperViewModel

    @State private var selectedType: DiaperType = .wet
    @State private var timestamp = Date()
    @State private var notes = ""
    @State private var showingTimePicker = false

    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        _viewModel = StateObject(wrappedValue: DiaperViewModel(context: context))
    }

    var body: some View {
        NavigationView {
            Form {

                if let selectedChild = childProfileViewModel.selectedChild {
                    Section(String(localized: "form_child")) {
                        HStack {
                            if let photoData = selectedChild.photoData,
                               let uiImage = UIImage(data: photoData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 40, height: 40)
                                    .clipShape(Circle())
                            } else {
                                Image(systemName: "person.circle.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.gray)
                            }

                            Text(selectedChild.name ?? "")
                                .font(.headline)
                        }
                    }
                }

                Section(String(localized: "form_type")) {
                    Picker(String(localized: "diaper_type_label"), selection: $selectedType) {
                        ForEach(DiaperType.allCases) { type in
                            HStack {
                                Image(systemName: type.icon)
                                    .foregroundColor(type.color)
                                Text(type.localizedName)
                            }
                            .tag(type)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }

                Section(String(localized: "form_time_label")) {
                    DatePicker(String(localized: "form_change_time"),
                              selection: $timestamp,
                              displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(.compact)
                }

                Section {
                    TextField(String(localized: "placeholder_notes"), text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                } header: {
                    Text(String(localized: "form_notes"))
                } footer: {
                    Text(String(localized: "diaper_add_info"))
                }
            }
            .navigationTitle(String(localized: "diaper_change_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "cancel")) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "save")) {
                        saveDiaperChange()
                    }
                    .disabled(childProfileViewModel.selectedChild == nil)
                }
            }
            .alert(String(localized: "error"), isPresented: $viewModel.showError) {
                Button(String(localized: "ok"), role: .cancel) {}
            } message: {
                if let error = viewModel.error {
                    Text(error.localizedDescription)
                }
            }
        }
    }

    private func saveDiaperChange() {
        guard let childId = childProfileViewModel.selectedChild?.id else {
            return
        }

        Task {
            await viewModel.addDiaperChange(
                childId: childId,
                timestamp: timestamp,
                diaperType: selectedType.localizedName,
                notes: notes.isEmpty ? nil : notes
            )

            if !viewModel.showError {
                dismiss()
            }
        }
    }
}

enum DiaperType: String, CaseIterable, Identifiable {
    case wet = "wet"
    case dirty = "dirty"
    case both = "both"

    var id: String { rawValue }

    var localizedName: String {
        switch self {
        case .wet:
            return String(localized: "diaper_type_wet")
        case .dirty:
            return String(localized: "diaper_type_dirty")
        case .both:
            return String(localized: "diaper_type_both")
        }
    }

    var icon: String {
        switch self {
        case .wet:
            return "drop.fill"
        case .dirty:
            return "sparkles"
        case .both:
            return "drop.triangle.fill"
        }
    }

    var color: Color {
        switch self {
        case .wet:
            return .blue
        case .dirty:
            return .brown
        case .both:
            return .orange
        }
    }
}

#if DEBUG
struct AddDiaperView_Previews: PreviewProvider {
    static var previews: some View {
        AddDiaperView(context: PersistenceController.preview.container.viewContext)
            .environmentObject(ChildProfileViewModel(context: PersistenceController.preview.container.viewContext))
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
#endif
