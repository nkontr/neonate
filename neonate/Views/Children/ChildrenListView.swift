import SwiftUI

struct ChildrenListView: View {

    @Environment(\.dismiss) private var dismiss

    @ObservedObject var viewModel: ChildProfileViewModel
    @State private var showAddChild = false
    @State private var childToEdit: ChildProfile?

    var body: some View {
        NavigationView {
            ZStack {
                if viewModel.children.isEmpty {
                    EmptyStateView(
                        icon: "person.2.fill",
                        title: "Нет профилей детей",
                        message: "Добавьте профиль вашего малыша",
                        actionTitle: "Добавить ребенка",
                        action: { showAddChild = true }
                    )
                } else {
                    List {
                        ForEach(viewModel.children, id: \.id) { child in
                            ChildProfileCard(
                                child: child,
                                isSelected: viewModel.selectedChild?.id == child.id,
                                onTap: {
                                    viewModel.selectChild(child)
                                },
                                viewModel: viewModel
                            )
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    Task {
                                        await viewModel.deleteChild(child)
                                    }
                                } label: {
                                    Label("Удалить", systemImage: "trash")
                                }

                                Button {
                                    childToEdit = child
                                } label: {
                                    Label("Изменить", systemImage: "pencil")
                                }
                                .tint(.blue)
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Профили детей")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showAddChild = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddChild) {
                AddChildView(viewModel: viewModel)
            }
            .sheet(item: $childToEdit) { child in
                EditChildView(viewModel: viewModel, child: child)
            }
        }
    }
}
