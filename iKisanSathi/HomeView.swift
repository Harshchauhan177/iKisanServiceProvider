import SwiftUI
import SDWebImageSwiftUI

struct FeatureCard: View {
    let title: String
    let subtitle: String
    let color: Color
    let isLarge: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                if isLarge {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(title)
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            Text(subtitle)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(color)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .frame(height: 100)
                    .background(
                        LinearGradient(gradient: Gradient(colors: [color.opacity(0.15), color.opacity(0.08)]), 
                                     startPoint: .topLeading, 
                                     endPoint: .bottomTrailing)
                    )
                    .cornerRadius(16)
                } else {
                    VStack(alignment: .leading, spacing: 4) {
                        Image(systemName: "house.fill")
                            .font(.title2)
                            .foregroundColor(color)
                        
                        Text(title)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text(subtitle)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct CategoryButton: View {
    let title: String
    let iconName: String
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Image(systemName: iconName)
                    .font(.title2)
                    .foregroundColor(.blue)
                    .frame(width: 50, height: 50)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(Circle())
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.primary)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct HomeView: View {
    @State private var isServiceRequestsActive = false
    @State private var isRequestsActive = false
    @State private var isIncomeAnalysisActive = false
    @EnvironmentObject var dataController: DataController
    @State private var showingProfile = false
    @State private var searchText = ""
    @Binding var selectedTab: Int
    @State private var showingAddEquipment = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Subtitle below large title
                    HStack {
                            Text("how are you today?")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top, 2)

                    // Add Equipment Card
                    Button {
                        showingAddEquipment = true
                    } label: {
                        HStack(spacing: 16) {
                            Image(systemName: "wrench.and.screwdriver.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.blue)
                                .frame(width: 40, height: 40)
                                .background(Color.blue.opacity(0.1))
                                .clipShape(Circle())
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Add Equipment")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Text("List your equipment for service")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(16)
                    }
                    .padding(.horizontal)
                    .sheet(isPresented: $showingAddEquipment) {
                        AddEquipmentView()
                    }
                    
                    // Quick Access Grid
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Quick Access")
                            .font(.title3)
                            .fontWeight(.bold)
                            .padding(.horizontal)
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                            QuickAccessButton(title: "Equipment", iconName: "wrench.and.screwdriver.fill", color: .blue) {
                                    selectedTab = 2
                                }
                            QuickAccessButton(title: "Request", iconName: "doc.fill", color: .green) {
                                    isRequestsActive = true
                                }
                            QuickAccessButton(title: "Service", iconName: "wrench.adjustable.fill", color: .purple) {
                                    isServiceRequestsActive = true
                                }
                            QuickAccessButton(title: "Income", iconName: "chart.line.uptrend.xyaxis", color: .orange) {
                                    isIncomeAnalysisActive = true
                                }
                            }
                            .padding(.horizontal)
                    }
                    
                    // Top Equipment
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Top Equipment")
                                .font(.title2)
                                .fontWeight(.semibold)
                            Spacer()
                            Button("See all") {
                                selectedTab = 2
                            }
                            .font(.body)
                            .foregroundColor(.blue)
                        }
                        .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(Array(dataController.equipmentDetails.values.prefix(5)), id: \.equipmentID) { equipment in
                                    TopEquipmentCard(equipment: equipment)
                                }
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 4)
                        }
                    }
                    // Top Equipment section
                    
                    // Active Requests Section
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Today's Active Requests")
                                .font(.title2)
                                .fontWeight(.semibold)
                            Spacer()
                            Button("See all") {
                                isServiceRequestsActive = true
                            }
                            .font(.body)
                            .foregroundColor(.blue)
                        }
                        .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                let sortedRequests = dataController.serviceRequests
                                    .filter { request in
                                        // Filter for today's requests
                                        let formatter = DateFormatter()
                                        formatter.dateFormat = "yyyy-MM-dd"
                                        let requestDate = formatter.date(from: String(request.date.prefix(10))) ?? Date()
                                        return Calendar.current.isDateInToday(requestDate)
                                    }
                                    .sorted { request1, request2 in
                                        // Sort by time remaining
                                        let formatter = DateFormatter()
                                        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
                                        let date1 = formatter.date(from: request1.date) ?? Date()
                                        let date2 = formatter.date(from: request2.date) ?? Date()
                                        return date1 < date2
                                    }
                                    .prefix(3)
                                
                                if sortedRequests.isEmpty {
                                    VStack(alignment: .center, spacing: 8) {
                                        Image(systemName: "calendar.badge.clock")
                                            .font(.system(size: 40))
                                            .foregroundColor(.gray)
                                        Text("No active requests for today")
                                            .font(.headline)
                                            .foregroundColor(.gray)
                                        Text("Total requests: \(dataController.serviceRequests.count)")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                    .frame(width: UIScreen.main.bounds.width - 32)
                                    .padding()
                                    .background(Color(.systemBackground))
                                    .cornerRadius(12)
                                } else {
                                    ForEach(Array(sortedRequests), id: \.id) { request in
                                        NavigationLink(destination: ServiceRequestDetailView(serviceRequest: request)) {
                                            VStack(alignment: .leading, spacing: 16) {
                                                HStack(spacing: 12) {
                                                    // Equipment Image
                                                    if let equipment = dataController.equipmentDetails[request.equipmentname],
                                                       let url = URL(string: equipment.equipmentImage) {
                                                        WebImage(url: url)
                                                            .resizable()
                                                            .scaledToFill()
                                                            .frame(width: 80, height: 80)
                                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                                    } else {
                                                        RoundedRectangle(cornerRadius: 12)
                                                            .fill(Color.gray.opacity(0.1))
                                                            .frame(width: 80, height: 80)
                                                            .overlay(
                                                                Image(systemName: "photo")
                                                                    .foregroundColor(.gray)
                                                            )
                                                    }
                                                    
                                                    // Equipment Details
                                                    VStack(alignment: .leading, spacing: 6) {
                                                        if let equipment = dataController.equipmentDetails[request.equipmentname] {
                                                            Text(equipment.name)
                                                                .font(.headline)
                                                                .foregroundColor(.primary)
                                                                .lineLimit(1)
                                                            
                                                            HStack {
                                                                Image(systemName: "wrench.and.screwdriver.fill")
                                                                    .foregroundColor(.blue)
                                                                    .font(.system(size: 12))
                                                                Text(equipment.type)
                                                                    .font(.subheadline)
                                                                    .foregroundColor(.secondary)
                                                            }
                                                            
                                                            HStack {
                                                                Image(systemName: "ruler.fill")
                                                                    .foregroundColor(.green)
                                                                    .font(.system(size: 12))
                                                                Text("\(String(format: "%.1f", request.area)) acres")
                                                                    .font(.subheadline)
                                                                    .foregroundColor(.secondary)
                                                            }
                                                        }
                                                    }
                                                    Spacer()
                                                }
            
                                                // Time and Date Section
                                                HStack {
                                                    // Date
                                                    HStack(spacing: 6) {
                                                        Image(systemName: "calendar")
                                                            .foregroundColor(.blue)
                                                            .font(.system(size: 14))
                                                        let date = String(request.date.prefix(10))
                                                        Text(date)
                                                            .font(.subheadline)
                                                            .foregroundColor(.primary)
                                                    }
                                                    
                                                    Spacer()
                                                    
                                                    // Time
                                                    HStack(spacing: 6) {
                                                        Image(systemName: "clock.fill")
                                                            .foregroundColor(.orange)
                                                            .font(.system(size: 14))
                                                        Text(request.timeslot.rawValue)
                                                            .font(.subheadline)
                                                            .foregroundColor(.primary)
                                                    }
                                                }
                                                .padding(.top, 4)
                                            }
                                            .padding(16)
                                            .frame(width: UIScreen.main.bounds.width - 32)
                                            .background(Color(.systemBackground))
                                            .cornerRadius(16)
                                            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 4)
                        }
                    }
                    
                    Spacer()
                }
                .padding(.top, 8)
            }
            .refreshable {
                await refreshHomeData()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Welcome" + (dataController.currentProducer?.name != nil ? ", \(dataController.currentProducer!.name)" : ""))
            .navigationBarTitleDisplayMode(.large)
            .navigationBarHidden(false)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: ProfileView()) {
                        if let urlString = dataController.currentProducer?.profileimage,
                           let url = URL(string: urlString),
                           !urlString.isEmpty {
                            WebImage(url: url)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 32, height: 32)
                                .clipped()
                                .clipShape(Circle())
                                .overlay(Group {
                                    if urlString.isEmpty {
                                        Image(systemName: "person.circle.fill")
                                            .resizable()
                                            .foregroundColor(.gray)
                                    }
                                })
                        } else {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .foregroundColor(.gray)
                                .frame(width: 32, height: 32)
                        }
                    }
                }
            }
            .navigationDestination(isPresented: $isRequestsActive) {
                RequestsView()
            }
            .navigationDestination(isPresented: $isServiceRequestsActive) {
                ServiceRequestsView()
            }
            .navigationDestination(isPresented: $isIncomeAnalysisActive) {
                MonthlyIncomeView()
            }
            .task {
                do {
                    try await dataController.fetchServiceRequests()
                    print("Fetched \(dataController.serviceRequests.count) service requests")
                } catch {
                    print("Error fetching service requests: \(error)")
                }
            }
            .navigationBarBackButtonHidden(false)
        }
    }
    
    private func refreshHomeData() async {
        do {
            try await dataController.refreshAllData()
        } catch {
            print("Error refreshing home data: \(error)")
        }
    }
}

// New QuickAccessButton for grid style
struct QuickAccessButton: View {
    let title: String
    let iconName: String
    let color: Color
    let onTap: () -> Void
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color(.secondarySystemBackground))
                        .frame(width: 56, height: 56)
                    Image(systemName: iconName)
                        .font(.system(size: 24))
                        .foregroundColor(color)
                }
                Text(title)
                    .font(.body)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity, minHeight: 100)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.03), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat
    var corners: UIRectCorner
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// Top Equipment Card with context menu for delete
struct TopEquipmentCard: View {
    let equipment: DataController.Equipment
    @State private var showingDeleteAlert = false
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    @EnvironmentObject var dataController: DataController
    
    var body: some View {
        NavigationLink(destination: EditEquipmentView(equipment: equipment)) {
            VStack(alignment: .leading, spacing: 0) {
                ZStack(alignment: .topTrailing) {
                    EquipmentImageCarousel(
                        mainImageUrl: equipment.equipmentImage,
                        equipmentID: equipment.equipmentID
                    )
                    .frame(width: 180, height: 180)
                    .clipped()
                    .clipShape(
                        RoundedCorner(radius: 12, corners: [.topLeft, .topRight])
                    )
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(equipment.name)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    // Pricing row
                    HStack {
                        // Per Hour
                        VStack(alignment: .leading) {
                            Text("Per Hour")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                            Text("₹\(String(format: "%.0f", equipment.pricePerHour))")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.primary)
                        }
                        
                        Spacer()
                        
                        // Per Acre
                        VStack(alignment: .leading) {
                            Text("Per Acre")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                            Text("₹\(String(format: "%.0f", equipment.pricePerAcre))")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.primary)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
            }
            .frame(width: 180)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
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
                        // Refresh data after deletion
                        try await dataController.fetchProducerEquipmentAndRequests()
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
