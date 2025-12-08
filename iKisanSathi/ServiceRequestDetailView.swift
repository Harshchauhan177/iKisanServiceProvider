import SwiftUI
import MapKit

struct ServiceRequestDetailView: View {
    let serviceRequest: DataController.ServiceRequest
    @EnvironmentObject var dataController: DataController
    @Environment(\.dismiss) var dismiss
    @State private var isConfirming = false
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer().frame(height: 1) // Add vertical space at the top
            // Equipment Card with StatusBadge vertically centered on the right
            ZStack {
                HStack(spacing: 16) {
                    AsyncImage(url: URL(string: dataController.equipmentDetails[serviceRequest.equipmentname]?.equipmentImage ?? "")) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Color.gray.opacity(0.3)
                    }
                    .frame(width: 70, height: 70)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    VStack(alignment: .leading, spacing: 4) {
                        Text(dataController.equipmentDetails[serviceRequest.equipmentname]?.name ?? "")
                            .font(.title3)
                            .fontWeight(.bold)
                        Text(dataController.equipmentDetails[serviceRequest.equipmentname]?.type ?? "")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text("Capacity: \(dataController.equipmentDetails[serviceRequest.equipmentname]?.capacity ?? "")")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding()
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
                .padding(.horizontal)
                // Centered StatusBadge overlay
                HStack {
                    Spacer()
                    StatusBadge(status: serviceRequest.status)
                }
                .padding(.trailing, 32)
            }
            .frame(height: 100) // Ensure enough height for vertical centering

            // Details Card
            VStack(alignment: .leading, spacing: 16) {
                DetailRow(icon: "calendar", text: serviceRequest.date)
                DetailRow(icon: "mappin.and.ellipse", text: serviceRequest.location)
                DetailRow(icon: "clock", text: "\(serviceRequest.timeslot.rawValue) • \(serviceRequest.timeperiod)")
                DetailRow(icon: "ruler", text: "\(String(format: "%.1f", serviceRequest.area)) acres")
                DetailRow(icon: "indianrupeesign.circle", text: "₹\(String(format: "%.2f", serviceRequest.amount))")
            }
            .padding()
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
            .padding(.horizontal)

            // Action Buttons
            HStack(spacing: 12) {
                // View on Map Button
                Button(action: {
                    openInMaps()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "map.fill")
                            .font(.subheadline)
                        Text("Get Directions")
                            .font(.subheadline.weight(.semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(14)
                }
                
                // Complete Service Button
                Button(action: {
                    isConfirming = true
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.subheadline)
                        Text("Complete")
                            .font(.subheadline.weight(.semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(14)
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)

            Spacer()
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("In Progress Requests")
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
    
    // Function to open Apple Maps with directions
    private func openInMaps() {
        let destination = serviceRequest.location
        
        // Create URL for Apple Maps with directions
        let encodedDestination = destination.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        if let url = URL(string: "maps://?daddr=\(encodedDestination)&dirflg=d") {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            } else {
                // Fallback to web-based Apple Maps
                if let webUrl = URL(string: "https://maps.apple.com/?daddr=\(encodedDestination)&dirflg=d") {
                    UIApplication.shared.open(webUrl, options: [:], completionHandler: nil)
                }
            }
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
