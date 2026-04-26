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
                        title: String(localized: "no_child_profiles"),
                        message: String(localized: "add_child_profile_message"),
                        actionTitle: String(localized: "add_child_button"),
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
                                    Label(String(localized: "action_delete"), systemImage: "trash")
                                }

                                Button {
                                    childToEdit = child
                                } label: {
                                    Label(String(localized: "action_edit"), systemImage: "pencil")
                                }
                                .tint(.blue)
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle(String(localized: "children_profiles_title"))
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
