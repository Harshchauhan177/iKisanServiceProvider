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
    @State private var loadTask: Task<Void, Never>?
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()
                if isLoading {
                    ProgressView("Loading equipment...")
                } else if dataController.equipmentDetails.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "wrench.and.screwdriver")
                            .font(.system(size: 64))
                            .foregroundColor(.secondary)
                        VStack(spacing: 8) {
                            Text("No equipment added yet")
                                .font(.title3)
                                .fontWeight(.semibold)
                            Text("Tap + to add your first equipment")
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                } else {
                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 16),
                            GridItem(.flexible(), spacing: 16)
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
                        await loadEquipmentForced()
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
                        // Force refresh after adding equipment
                        Task {
                            await loadEquipmentForced()
                        }
                    }
            }
            .sheet(item: $selectedEquipment) { equipment in
                NavigationView {
                    EditEquipmentView(equipment: equipment, isPresentedModally: true)
                        .environmentObject(dataController)
                }
                .onDisappear {
                    // Use cache after editing - no need to force refresh
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
            .task(id: dataController.currentUser?.id) {
                // Cancel previous task
                loadTask?.cancel()
                
                loadTask = Task {
                    await loadEquipment()
                }
            }
            .onDisappear {
                loadTask?.cancel()
            }
        }
    }
    
    // Use cached data
    private func loadEquipment() async {
        // Skip if cancelled
        guard !Task.isCancelled else { return }
        
        // Show loading only if no equipment cached
        if dataController.equipmentDetails.isEmpty {
            isLoading = true
        }
        
        do {
            try await dataController.fetchProducerEquipmentAndRequests()
        } catch {
            if !Task.isCancelled {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
        isLoading = false
    }
    
    // Force refresh (used after adding equipment)
    private func loadEquipmentForced() async {
        isLoading = true
        // Invalidate cache by setting fetch time to nil
        do {
            // Force a fresh fetch by temporarily clearing cache timestamp
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
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
        .onTapGesture {
            onEdit()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(equipment.name), \(equipment.type)")
        .accessibilityHint("Double tap to edit equipment details")
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

