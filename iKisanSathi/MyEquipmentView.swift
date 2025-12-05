import SwiftUI
import SDWebImageSwiftUI

// New view for displaying multiple equipment images
struct EquipmentImageCarousel: View {
    let mainImageUrl: String
    let equipmentID: UUID
    @EnvironmentObject var dataController: DataController
    @State private var additionalImages: [String] = []
    @State private var currentImageIndex = 0
    
    private var allImages: [String] {
        var images = [mainImageUrl]
        images.append(contentsOf: additionalImages)
        return images
    }
    
    var body: some View {
        VStack {
            if allImages.count > 1 {
                TabView(selection: $currentImageIndex) {
                    ForEach(Array(allImages.enumerated()), id: \.offset) { index, imageUrl in
                        WebImage(url: URL(string: imageUrl))
                            .resizable()
                            .scaledToFill()
                            .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
                .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
            } else {
                WebImage(url: URL(string: mainImageUrl))
                    .resizable()
                    .scaledToFill()
            }
        }
        .task {
            await loadAdditionalImages()
        }
    }
    
    private func loadAdditionalImages() async {
        do {
            let images = try await dataController.fetchEquipmentMoreImages(equipmentID: equipmentID)
            await MainActor.run {
                self.additionalImages = images
            }
        } catch {
            print("Failed to load additional images: \(error)")
        }
    }
}

struct MyEquipmentView: View {
    @EnvironmentObject var dataController: DataController
    @State private var showingAddEquipment = false
    @State private var selectedEquipment: DataController.Equipment?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showError = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()
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
                    .environmentObject(dataController)
                    .onDisappear {
                        Task {
                            await loadEquipment()
                        }
                    }
            }
            .sheet(item: $selectedEquipment) { equipment in
                NavigationView {
                    EditEquipmentView(equipment: equipment, isPresentedModally: true)
                        .environmentObject(dataController)
                }
                .onDisappear {
                    Task {
                        await loadEquipment()
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
    @State private var showingDeleteAlert = false
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    @EnvironmentObject var dataController: DataController
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            GeometryReader { geometry in
                EquipmentImageCarousel(
                    mainImageUrl: equipment.equipmentImage,
                    equipmentID: equipment.equipmentID
                )
                .frame(width: geometry.size.width, height: geometry.size.width)
                .clipped()
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
        .onTapGesture {
            onEdit()
        }
        .contextMenu {
            Button(role: .destructive) {
                showingDeleteAlert = true
            } label: {
                Label("Delete", systemImage: "trash")
            }
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
    }
}

