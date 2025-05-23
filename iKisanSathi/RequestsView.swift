import SwiftUI
import SDWebImageSwiftUI

struct RequestsView: View {
    @EnvironmentObject var dataController: DataController
    @State private var isLoading = true
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(.systemGray6),
                    Color(.systemGray5).opacity(0.5)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
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
                                .padding(.horizontal)
                        }
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
    @State private var showingEditSheet = false
    
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
                            
                            // Time Slot next to name
                            HStack(spacing: 6) {
                                Image(systemName: "clock")
                                    .foregroundColor(.orange)
                                Text("\(request.timePeriod ?? "")")
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
                        if let date = request.date {
                            Text(date, style: .date)
                                .font(.subheadline)
                                .foregroundColor(.primary)
                        }
                    }
                    
                    Spacer()
                    
                    // Area
                    if request.type == .coEquip {
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
                
                // Action Buttons
                HStack(spacing: 12) {
                    Button(action: {
                        Task {
                            await handleAcceptRequest()
                        }
                    }) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Accept")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    
                    Button(action: {
                        Task {
                            await handleDeleteRequest()
                        }
                    }) {
                        HStack {
                            Image(systemName: "trash.fill")
                            Text("Delete")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                }
                .font(.subheadline.bold())
            }
        }
        .padding(16)
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
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .sheet(isPresented: $showingEditSheet) {
            if let equipment = equipment {
                EditEquipmentView(equipment: equipment)
            }
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
}

//#Preview {
//    RequestsView()
//        .environmentObject(DataController())
//}
