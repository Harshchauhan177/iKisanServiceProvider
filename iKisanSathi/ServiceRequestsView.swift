import SwiftUI

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
                                    .padding(.horizontal)
                                    .padding(.vertical, 8)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
            }
        }
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let equipment = equipment {
                HStack(alignment: .top, spacing: 12) {
                    // Equipment image container
                    AsyncImage(url: URL(string: equipment.equipmentImage)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Color(.systemGray5)
                            .overlay(
                                Image(systemName: "photo")
                                    .font(.system(size: 24))
                                    .foregroundColor(.gray)
                            )
                    }
                    .frame(width: 90, height: 90)
                    .cornerRadius(10)
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text(equipment.name)
                            .font(.system(.headline, design: .rounded))
                            .foregroundColor(.primary)
                        
                        Text(equipment.type)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text("Capacity: \(equipment.capacity)")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .padding(.top, 2)
                    }
                    
                    Spacer()
                }
                
                Divider()
                    .padding(.vertical, 4)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                infoRow(icon: "calendar") {
                    Text(request.date)
                }
                
                infoRow(icon: "mappin.and.ellipse") {
                    Text(request.location)
                }
                
                infoRow(icon: "clock") {
                    HStack {
                        Text(request.timeslot.rawValue)
                        Text("•")
                        Text(request.timeperiod)
                    }
                }
                
//                infoRow(icon: "ruler") {
//                    Text("\(String(format: "%.1f", request.area)) acres")
//                }
                
                infoRow(icon: "indianrupeesign.circle") {
                    Text("₹\(String(format: "%.2f", request.amount))")
                }
                
                HStack {
                    StatusBadge(status: request.status)
                    Spacer()
                    Text(request.type.rawValue)
                        .font(.footnote.weight(.medium))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 4)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color(.systemGray4).opacity(0.3), radius: 8, x: 0, y: 2)
        )
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
