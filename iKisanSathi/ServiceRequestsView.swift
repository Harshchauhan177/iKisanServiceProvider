import SwiftUI
import SDWebImageSwiftUI

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
                VStack(spacing: 12) {
                    Image(systemName: "archivebox")
                        .font(.system(size: 50))
                        .foregroundColor(Color(.systemGray4))
                    Text("No service requests found")
                        .font(.system(size: 17))
                        .foregroundColor(Color(.systemGray))
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
}

struct ServiceRequestRow: View {
    @Environment(\.colorScheme) var colorScheme
    let request: DataController.ServiceRequest
    let equipment: DataController.Equipment?
    @State private var isLoading = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with Equipment Image and Details
            HStack(spacing: 12) {
                if let equipment = equipment {
                    WebImage(url: URL(string: equipment.equipmentImage))
                        .resizable()
                        .scaledToFill()
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color(.systemGray5), lineWidth: 1)
                        )
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(equipment.name)
                                .font(.headline)
                                .foregroundColor(.primary)
                            Spacer()
                            // Time Slot
                            HStack(spacing: 6) {
                                Image(systemName: "clock")
                                    .foregroundColor(.orange)
                                Text(request.timeperiod)
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                            }
                        }
                        Text(equipment.type)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text("Capacity: \(equipment.capacity)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
            }
            // Request Details
            VStack(spacing: 12) {
                // Date and Area
                HStack {
                    // Date
                    HStack(spacing: 6) {
                        Image(systemName: "calendar")
                            .foregroundColor(.blue)
                        Text(request.date)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                    }
                    Spacer()
                    // Area (if available)
                    if request.area > 0 {
                        Text("\(String(format: "%.1f", request.area)) acres")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
                Divider()
                // Status and Type
                HStack {
                    StatusBadge(status: request.status)
                    Spacer()
                    Text(request.type.rawValue)
                        .font(.footnote.weight(.medium))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading) // Make card fill width
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        .overlay(Group {
            if isLoading {
                Color.black.opacity(0.3)
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
            }
        })
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
    
    var body: some View {
        Text(status.rawValue)
            .font(.footnote.weight(.medium))
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor)
            .cornerRadius(8)
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
