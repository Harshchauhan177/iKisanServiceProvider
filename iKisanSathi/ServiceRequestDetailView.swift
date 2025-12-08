import SwiftUI
import MapKit

struct ServiceRequestDetailView: View {
    let serviceRequest: DataController.ServiceRequest
    @EnvironmentObject var dataController: DataController
    @Environment(\.dismiss) var dismiss
    @State private var isConfirming = false
    
    // Check if the service date is today
    private var isServiceDateToday: Bool {
        guard let serviceDate = parseServiceDate() else {
            return false
        }
        
        let calendar = Calendar.current
        return calendar.isDateInToday(serviceDate)
    }
    
    // Helper function to parse service date with multiple format attempts
    private func parseServiceDate() -> Date? {
        // Try multiple date formats
        let formats = [
            "yyyy-MM-dd'T'HH:mm:ss",
            "yyyy-MM-dd",
            "yyyy-MM-dd'T'HH:mm:ssZ",
            "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        ]
        
        for format in formats {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = format
            dateFormatter.locale = Locale(identifier: "en_US_POSIX")
            dateFormatter.timeZone = TimeZone.current
            
            if let date = dateFormatter.date(from: serviceRequest.date) {
                return date
            }
        }
        
        return nil
    }
    
    // Get a user-friendly message for when Complete is disabled
    private var completeButtonMessage: String {
        guard let serviceDate = parseServiceDate() else {
            return "Invalid date format"
        }
        
        let calendar = Calendar.current
        if calendar.isDateInToday(serviceDate) {
            return "Mark as completed"
        } else if serviceDate > Date() {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            return "Available on \(dateFormatter.string(from: serviceDate))"
        } else {
            return "Service date has passed"
        }
    }
    
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
                    if isServiceDateToday {
                        isConfirming = true
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: isServiceDateToday ? "checkmark.circle.fill" : "clock.badge.checkmark")
                            .font(.subheadline)
                        Text(isServiceDateToday ? "Complete" : "Complete")
                            .font(.subheadline.weight(.semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isServiceDateToday ? Color.green : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(14)
                    .opacity(isServiceDateToday ? 1.0 : 0.6)
                }
                .disabled(!isServiceDateToday)
            }
            .padding(.horizontal)
            .padding(.top, 8)
            
            // Helper text for Complete button
            if !isServiceDateToday {
                Text(completeButtonMessage)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

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
