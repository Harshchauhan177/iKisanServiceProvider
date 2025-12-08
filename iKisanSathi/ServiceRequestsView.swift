import SwiftUI
import SDWebImageSwiftUI
import MapKit

struct ServiceRequestsView: View {
    @EnvironmentObject var dataController: DataController
    @State private var isLoading = true
    
    private var inProgressRequests: [DataController.ServiceRequest] {
        dataController.serviceRequests.filter { $0.status == .inProgress }
    }
    
    var body: some View {
        ZStack {
            if isLoading {
                ProgressView()
            } else if inProgressRequests.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "archivebox")
                        .font(.system(size: 64))
                        .foregroundColor(.secondary)
                    VStack(spacing: 8) {
                        Text("No service requests found")
                            .font(.title3)
                            .fontWeight(.semibold)
                        Text("Your active requests will appear here")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(inProgressRequests, id: \.id) { request in
                            NavigationLink(destination: ServiceRequestDetailView(serviceRequest: request)) {
                                ServiceRequestRow(request: request, equipment: dataController.equipmentDetails[request.equipmentname])
                                    .padding(.vertical, 8)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal) // Move horizontal padding here
                    .padding(.vertical)
                }
                .refreshable {
                    await refreshData()
                }
            }
        }
        .background(Color(.systemGray6).ignoresSafeArea())
        .navigationTitle("In Progress Requests")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            isLoading = true
            do {
                try await dataController.fetchServiceRequests()
            } catch {
                print("Error fetching service requests: \(error)")
            }
            isLoading = false
        }
    }
    
    private func refreshData() async {
        do {
            try await dataController.refreshAllData()
        } catch {
            print("Error refreshing service requests: \(error)")
        }
    }
}

struct ServiceRequestRow: View {
    @Environment(\.colorScheme) var colorScheme
    let request: DataController.ServiceRequest
    let equipment: DataController.Equipment?
    @State private var isLoading = false
    
    // Helper to get time slot display name
    private var timeSlotText: String {
        switch request.timeslot {
        case .morning:
            return "Morning"
        case .afternoon:
            return "Afternoon"
        case .evening:
            return "Evening"
        }
    }
    
    // Helper to get time slot icon color
    private var timeSlotColor: Color {
        switch request.timeslot {
        case .morning:
            return .orange
        case .afternoon:
            return .yellow
        case .evening:
            return .indigo
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with Equipment Image and Details
            HStack(spacing: 12) {
                if let equipment = equipment {
                    WebImage(url: URL(string: equipment.equipmentImage))
                        .resizable()
                        .scaledToFill()
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(.systemGray5), lineWidth: 1)
                        )
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text(equipment.name)
                            .font(.headline)
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        
                        Text(equipment.type)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                        
                        HStack(spacing: 4) {
                            Image(systemName: "scalemass")
                                .font(.caption2)
                            Text(equipment.capacity)
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                    }
                    Spacer()
                }
            }
            
            Divider()
            
            // Request Details Grid
            VStack(spacing: 12) {
                // Date and Time Slot Row
                HStack(spacing: 12) {
                    // Date
                    HStack(spacing: 6) {
                        Image(systemName: "calendar")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                            .frame(width: 20)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Date")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text(request.date)
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(.primary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Time Slot
                    HStack(spacing: 6) {
                        Image(systemName: "clock.fill")
                            .font(.subheadline)
                            .foregroundColor(timeSlotColor)
                            .frame(width: 20)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Time Slot")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text(timeSlotText)
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(.primary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                // Area and Type Row
                HStack(spacing: 12) {
                    // Area
                    if request.area > 0 {
                        HStack(spacing: 6) {
                            Image(systemName: "map")
                                .font(.subheadline)
                                .foregroundColor(.green)
                                .frame(width: 20)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Area")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                Text("\(String(format: "%.1f", request.area)) acres")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundColor(.primary)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    // Request Type
                    HStack(spacing: 6) {
                        Image(systemName: request.type == .coequip ? "person.2.fill" : "person.fill")
                            .font(.subheadline)
                            .foregroundColor(request.type == .coequip ? .purple : .blue)
                            .frame(width: 20)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Type")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text(request.type == .coequip ? "Co-Equip" : "Individual")
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(.primary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                Divider()
                
                // Status and Action Row
                HStack(spacing: 12) {
                    StatusBadge(status: request.status)
                    Spacer()
                    
                    // View on Map Button
                    Button(action: {
                        openInMaps()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "map.fill")
                                .font(.caption)
                            Text("Directions")
                                .font(.footnote.weight(.semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.blue)
                        .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading) // Make card fill width
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
        .overlay(Group {
            if isLoading {
                Color.black.opacity(0.3)
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
            }
        })
    }
    
    // Function to open Apple Maps with directions
    private func openInMaps() {
        // Parse location to get coordinates or address
        let destination = request.location
        
        // Create URL for Apple Maps with directions
        // Format: maps://?daddr=<destination>&dirflg=d
        // dirflg=d means driving directions
        let encodedDestination = destination.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        // Use current location as starting point (saddr parameter not needed, Maps uses current location by default)
        if let url = URL(string: "maps://?daddr=\(encodedDestination)&dirflg=d") {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            } else {
                // Fallback to web-based Apple Maps if app is not available
                if let webUrl = URL(string: "https://maps.apple.com/?daddr=\(encodedDestination)&dirflg=d") {
                    UIApplication.shared.open(webUrl, options: [:], completionHandler: nil)
                }
            }
        }
    }
    
    private func infoRow<Content: View>(
        icon: String,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .frame(width: 20)
                .foregroundColor(.secondary)
            content()
                .foregroundColor(.primary)
        }
        .font(.subheadline)
    }
}

struct StatusBadge: View {
    let status: DataController.ServiceStatus
    
    private var statusIcon: String {
        switch status {
        case .pending:
            return "clock.badge.exclamationmark"
        case .inProgress:
            return "gearshape.2.fill"
        case .completed:
            return "checkmark.circle.fill"
        case .cancelled:
            return "xmark.circle.fill"
        case .new:
            return "sparkles"
        case .all:
            return "list.bullet"
        }
    }
    
    private var statusText: String {
        switch status {
        case .pending:
            return "Pending"
        case .inProgress:
            return "In Progress"
        case .completed:
            return "Completed"
        case .cancelled:
            return "Cancelled"
        case .new:
            return "New"
        case .all:
            return "All"
        }
    }
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: statusIcon)
                .font(.caption)
            Text(statusText)
                .font(.footnote.weight(.semibold))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(statusColor)
        .clipShape(Capsule())
        .shadow(color: statusColor.opacity(0.3), radius: 4, x: 0, y: 2)
    }
    
    private var statusColor: Color {
        switch status {
        case .pending:
            return .orange
        case .inProgress:
            return .blue
        case .completed:
            return .green
        case .all:
            return .accentColor
        case .cancelled:
            return .red
        case .new:
            return .yellow
        }
    }
}
