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
                    HStack {
                        ZStack {
                            Circle()
                                .fill(Color.blue.opacity(0.15))
                                .frame(width: 56, height: 56)
                            Image(systemName: "wrench.and.screwdriver.fill")
                                .font(.system(size: 28))
                                .foregroundColor(.blue)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Add Equipment")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            Text("List your equipment for service")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(20)
                    .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
                    .padding(.horizontal)
                    .onTapGesture {
                            selectedTab = 2
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
                                .font(.title3)
                                .fontWeight(.bold)
                            Spacer()
                            Button("See all") {
                                selectedTab = 2
                            }
                            .foregroundColor(.blue)
                        }
                        .padding(.horizontal)
                        // Keep the equipment cards horizontally scrollable as before
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(Array(dataController.equipmentDetails.values.prefix(5)), id: \ .equipmentID) { equipment in
                                    VStack(alignment: .leading, spacing: 8) {
                                        if let url = URL(string: equipment.equipmentImage) {
                                            WebImage(url: url)
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 140, height: 100)
                                                .clipped()
                                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                                .overlay(Group {
                                                    if !equipment.equipmentImage.isEmpty {
                                                        EmptyView()
                                                    } else {
                                                        Color.gray.opacity(0.3)
                                                    }
                                                })
                                        } else {
                                            Color.gray.opacity(0.3)
                                                .frame(width: 140, height: 100)
                                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                        }
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
                .padding(.top, 8)
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
                } catch {
                    print("Error fetching service requests: \(error)")
                }
            }
            .navigationBarBackButtonHidden(false)
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
                        .fill(color.opacity(0.15))
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
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.03), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
