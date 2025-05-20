import SwiftUI

struct ServiceRequestDetailView: View {
    let serviceRequest: DataController.ServiceRequest
    @EnvironmentObject var dataController: DataController
    @Environment(\.dismiss) var dismiss
    @State private var isConfirming = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Equipment Image and Details
                HStack(alignment: .top, spacing: 15) {
                    AsyncImage(url: URL(string: dataController.equipmentDetails[serviceRequest.equipmentname]?.equipmentImage ?? "")) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Color.gray.opacity(0.3)
                    }
                    .frame(width: 100, height: 100)
                    .cornerRadius(10)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text(dataController.equipmentDetails[serviceRequest.equipmentname]?.name ?? "")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text(dataController.equipmentDetails[serviceRequest.equipmentname]?.type ?? "")
                            .foregroundColor(.gray)
                        
                        Text("Capacity: \(dataController.equipmentDetails[serviceRequest.equipmentname]?.capacity ?? "")")
                            .foregroundColor(.gray)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                
                // Request Details
                VStack(alignment: .leading, spacing: 15) {
                    DetailRow(icon: "calendar", text: serviceRequest.date)
                    DetailRow(icon: "mappin.and.ellipse", text: serviceRequest.location)
                    DetailRow(icon: "clock", text: "\(serviceRequest.timeslot.rawValue) • \(serviceRequest.timeperiod)")
                    DetailRow(icon: "ruler", text: "\(String(format: "%.1f", serviceRequest.area)) acres")
                    DetailRow(icon: "indianrupeesign.circle", text: "₹\(String(format: "%.2f", serviceRequest.amount))")
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                
                // Status Badge
                HStack {
                    Spacer()
                    StatusBadge(status: serviceRequest.status)
                    Spacer()
                }
                
                // Confirm Button
                Button(action: {
                    isConfirming = true
                }) {
                    Text("Complete Service")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.top)
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
        .alert("Complete Service Request", isPresented: $isConfirming) {
            Button("Cancel", role: .cancel) { }
            Button("Complete", role: .destructive) {
                Task {
                    try? await dataController.completeServiceRequest(serviceRequest)
                    dismiss()
                }
            }
        } message: {
            Text("Are you sure you want to mark this service as completed?")
        }
    }
}

struct DetailRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            Text(text)
                .foregroundColor(.primary)
            Spacer()
        }
    }
}
