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
                    Section("Ребенок") {
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

                Section("Тип") {
                    Picker("Тип подгузника", selection: $selectedType) {
                        ForEach(DiaperType.allCases) { type in
                            HStack {
                                Image(systemName: type.icon)
                                    .foregroundColor(type.color)
                                Text(type.rawValue)
                            }
                            .tag(type)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }

                Section("Время") {
                    DatePicker("Время смены",
                              selection: $timestamp,
                              displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(.compact)
                }

                Section {
                    TextField("Заметки (опционально)", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                } header: {
                    Text("Заметки")
                } footer: {
                    Text("Добавьте дополнительную информацию о смене подгузника")
                }

                Section {
                    SiriShortcutButton(
                        shortcutType: .diaper,
                        title: "Скажите Siri для быстрого добавления смены"
                    )
                }
            }
            .navigationTitle("Смена подгузника")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить") {
                        saveDiaperChange()
                    }
                    .disabled(childProfileViewModel.selectedChild == nil)
                }
            }
            .alert("Ошибка", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) {}
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
                diaperType: selectedType.rawValue,
                notes: notes.isEmpty ? nil : notes
            )

            if !viewModel.showError {
                dismiss()
            }
        }
    }
}

enum DiaperType: String, CaseIterable, Identifiable {
    case wet = "Мокрый"
    case dirty = "Грязный"
    case both = "Оба"

    var id: String { rawValue }

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
