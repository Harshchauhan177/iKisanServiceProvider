import SwiftUI

struct MyEquipmentView: View {
    @EnvironmentObject var dataController: DataController
    @State private var showingAddEquipment = false
    @State private var selectedEquipment: DataController.Equipment?
    @State private var showingEditSheet = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showError = false
    
    var body: some View {
        NavigationView {
            ZStack {
                if isLoading {
                    ProgressView("Loading equipment...")
                } else if dataController.equipmentDetails.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "wrench.and.screwdriver")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("No equipment added yet")
                            .font(.headline)
                        Text("Tap + to add your first equipment")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                } else {
                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 16) {
                            ForEach(Array(dataController.equipmentDetails.values), id: \.equipmentID) { equipment in
                                EquipmentCard(equipment: equipment, onEdit: {
                                    selectedEquipment = equipment
                                    showingEditSheet = true
                                })
                                .padding(4)
                            }
                        }
                        .padding()
                    }
                    .refreshable {
                        await loadEquipment()
                    }
                }
            }
            .navigationTitle("My Equipment")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddEquipment = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddEquipment) {
                AddEquipmentView()
                    .onDisappear {
                        Task {
                            await loadEquipment()
                        }
                    }
            }
            .sheet(isPresented: $showingEditSheet) {
                if let equipment = selectedEquipment {
                    EditEquipmentView(equipment: equipment)
                        .onDisappear {
                            Task {
                                await loadEquipment()
                            }
                        }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage ?? "An unknown error occurred")
            }
            .task {
                await loadEquipment()
            }
        }
    }
    
    private func loadEquipment() async {
        isLoading = true
        do {
            try await dataController.fetchProducerEquipmentAndRequests()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        isLoading = false
    }
}

struct EquipmentCard: View {
    let equipment: DataController.Equipment
    let onEdit: () -> Void
    @State private var showingActionSheet = false
    @State private var showingDeleteAlert = false
    @State private var showingEditSheet = false
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    @EnvironmentObject var dataController: DataController
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            GeometryReader { geometry in
                ZStack(alignment: .topTrailing) {
                    Color(.systemGray5)
                    AsyncImage(url: URL(string: equipment.equipmentImage)) { phase in
                        switch phase {
                        case .empty:
                            Image(systemName: "photo")
                                .font(.system(size: 24))
                                .foregroundColor(.gray)
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: geometry.size.width, height: geometry.size.width)
                        case .failure(_):
                            Image(systemName: "photo")
                                .font(.system(size: 24))
                                .foregroundColor(.gray)
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .clipped()
                    
                    Button {
                        showingActionSheet = true
                    } label: {
                        Image(systemName: "ellipsis")
                            .foregroundColor(.white)
                            .padding(6)
                            .background(Circle().fill(Color.black.opacity(0.6)))
                            .padding(8)
                    }
                }
            }
            .aspectRatio(1, contentMode: .fit)
            
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(equipment.name)
                        .font(.headline)
                        .lineLimit(1)
                    Spacer()
                }
                
                HStack {
                    Text("Per Hour")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("Per Acre")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("₹\(String(format: "%.0f", equipment.pricePerHour))")
                        .font(.subheadline)
                    Spacer()
                    Text("₹\(String(format: "%.0f", equipment.pricePerAcre))")
                        .font(.subheadline)
                }
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 8)
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color(.systemGray4).opacity(0.3), radius: 4, x: 0, y: 2)
        .confirmationDialog("Equipment Actions", isPresented: $showingActionSheet) {
            Button("Edit") {
                onEdit()
            }
            Button("Delete", role: .destructive) {
                showingDeleteAlert = true
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Choose an action")
        }
        .alert("Delete Equipment", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task {
                    do {
                        try await dataController.deleteEquipment(id: equipment.equipmentID)
                    } catch {
                        errorMessage = error.localizedDescription
                        showingErrorAlert = true
                    }
                }
            }
        } message: {
            Text("Are you sure you want to delete this equipment? This action cannot be undone.")
        }
        .alert("Error", isPresented: $showingErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .sheet(isPresented: $showingEditSheet) {
            EditEquipmentView(equipment: equipment)
        }
    }
}

