import SwiftUI

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
                                .foregroundColor(.white)
                            
                            Text(subtitle)
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.9))
                        }
                        Spacer()
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .frame(height: 100)
                    .background(
                        LinearGradient(gradient: Gradient(colors: [color, color.opacity(0.8)]), 
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
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Hello ")
                                .font(.title2)
                                .fontWeight(.bold)
                            Text("how are you today?")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        HStack(spacing: 16) {
                            Button(action: { /* Search action */ }) {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(.primary)
                            }
                            NavigationLink(destination: ProfileView()) {
                                Image(systemName: "bell.fill")
                                    .foregroundColor(.primary)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Feature Cards
                    VStack(spacing: 16) {
                        FeatureCard(
                            title: "Add Equipment",
                            subtitle: "List your equipment for service",
                            color: .blue,
                            isLarge: true
                        ) {
                            selectedTab = 2
                        }
                        
                        FeatureCard(
                            title: "View Requests",
                            subtitle: "Check rental requests",
                            color: .purple,
                            isLarge: true
                        ) {
                            isRequestsActive = true
                        }
                    }
                    .padding(.horizontal)
                    
                    // Categories
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Quick Access")
                            .font(.title3)
                            .fontWeight(.bold)
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 24) {
                                CategoryButton(title: "Equipment", iconName: "wrench.and.screwdriver.fill") {
                                    selectedTab = 2
                                }
                                CategoryButton(title: "Requests", iconName: "bell.fill") {
                                    isRequestsActive = true
                                }
                                CategoryButton(title: "Services", iconName: "clock.fill") {
                                    isServiceRequestsActive = true
                                }
                                CategoryButton(title: "Income", iconName: "indianrupeesign.circle.fill") {
                                    isIncomeAnalysisActive = true
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // Top Equipment
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Top Equipment")
                                .font(.title3)
                                .fontWeight(.bold)
                            Spacer()
                            Button("See all") {
                                selectedTab = 2
                            }
                            .foregroundColor(.blue)
                        }
                        .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(Array(dataController.equipmentDetails.values.prefix(5)), id: \.equipmentID) { equipment in
                                    VStack(alignment: .leading, spacing: 8) {
                                        AsyncImage(url: URL(string: equipment.equipmentImage)) { phase in
                                            switch phase {
                                            case .empty:
                                                Color.gray.opacity(0.3)
                                            case .success(let image):
                                                image
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fill)
                                            case .failure:
                                                Color.gray.opacity(0.3)
                                            @unknown default:
                                                EmptyView()
                                            }
                                        }
                                        .frame(width: 140, height: 100)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                        
                                        Text(equipment.name)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .lineLimit(1)
                                        
                                        Text("₹\(String(format: "%.0f", equipment.pricePerHour))/hr")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .frame(width: 140)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarHidden(true)
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
                } catch {
                    print("Error fetching service requests: \(error)")
                }
            }
            .navigationBarBackButtonHidden(false)
        }
    }
}
