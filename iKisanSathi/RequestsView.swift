import SwiftUI

struct RequestsView: View {
    @EnvironmentObject var dataController: DataController
    @State private var isLoading = true
    
    var body: some View {
        ZStack {
            if isLoading {
                ProgressView()
            } else if dataController.producerRequests.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "archivebox")
                        .font(.system(size: 50))
                        .foregroundColor(Color(.systemGray4))
                    Text("No requests found")
                        .font(.system(size: 17))
                        .foregroundColor(Color(.systemGray))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(dataController.producerRequests) { request in
                            RequestRow(request: request, equipment: dataController.equipmentDetails[request.equipmentId ?? UUID()])
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
            }
        }
        .navigationTitle("New Requests")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            isLoading = true
            do {
                try await dataController.fetchProducerEquipmentAndRequests()
            } catch {
                print("Error fetching requests: \(error)")
            }
            isLoading = false
        }
        }
    }


struct RequestRow: View {
    let request: Request
    let equipment: DataController.Equipment?
    @EnvironmentObject var dataController: DataController
    @State private var isPressed = false
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let equipment = equipment {
                HStack(spacing: 16) {
                    // Equipment Image
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
                    .frame(width: 100, height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    // Equipment Details
                    VStack(alignment: .leading, spacing: 4) {
                        Text(equipment.name)
                            .font(.title3)
                            .fontWeight(.semibold)
                        
                        Text(equipment.type)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text("Capacity: \(equipment.capacity)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
            }
            
            // Request Details
            VStack(spacing: 16) {
                HStack(spacing: 24) {
                    // Date with acres
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Image(systemName: "calendar")
                                .foregroundColor(.blue)
                            if let date = request.date {
                                Text(date, style: .date)
                                    .fontWeight(.medium)
                            }
                        }
                        if request.type == .coEquip {
                            Text("\(String(format: "%.1f", request.area)) acres")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(6)
                        }
                    }
                    
                    Divider()
                    
                    // Location
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Image(systemName: "location.fill")
                                .foregroundColor(.red)
                            Text(request.location)
                                .fontWeight(.medium)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                
                Divider()
                    .padding(.horizontal, 16)
                
                // Time and Type
                HStack(spacing: 24) {
                    // Time
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Image(systemName: "clock.fill")
                                .foregroundColor(.orange)
                            Text(request.timeSlot.rawValue)
                                .fontWeight(.medium)
                        }
                        if let period = request.timePeriod {
                            Text(period)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Divider()
                    
                    // Request Type
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Image(systemName: "bell.fill")
                                .foregroundColor(.purple)
                            Text(request.typeOfRequest.rawValue)
                                .fontWeight(.medium)
                        }
                        Text(request.type.rawValue)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                
                // Action Buttons
                HStack(spacing: 16) {
                    Button(action: {
                        Task {
                            await handleAcceptRequest()
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Accept")
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(gradient: Gradient(colors: [Color.green, Color.green.opacity(0.8)]),
                                         startPoint: .topLeading,
                                         endPoint: .bottomTrailing)
                        )
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    
                    Button(action: {
                        Task {
                            await handleDeleteRequest()
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "trash.fill")
                            Text("Delete")
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(gradient: Gradient(colors: [Color.red, Color.red.opacity(0.8)]),
                                         startPoint: .topLeading,
                                         endPoint: .bottomTrailing)
                        )
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .disabled(isLoading)
                .opacity(isLoading ? 0.6 : 1)
            }
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
        .overlay(Group {
            if isLoading {
                Color.black.opacity(0.3)
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
            }
        })
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
    }
    
    private func infoRow<Content: View>(
        icon: String,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .frame(width: 20)
            content()
        }
    }
    
    private func handleAcceptRequest() async {
        isLoading = true
        do {
            try await dataController.acceptRequest(request)
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    private func handleDeleteRequest() async {
        isLoading = true
        do {
            try await dataController.deleteRequest(request)
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    private var statusColor: Color {
        switch request.status {
        case .pending:
            return .orange
        case .confirmed:
            return .green
//        case .rejected:
//            return .red
        case .completed:
            return .blue
        }
    }
}

//#Preview {
//    RequestsView()
//        .environmentObject(DataController())
//}
