import SwiftUI
import SDWebImageSwiftUI

struct CoEquipRequestsView: View {
    @EnvironmentObject var dataController: DataController
    @State private var isLoading = true
    @State private var loadTask: Task<Void, Never>?

    private var pendingRequests: [DataController.CoEquipRequest] {
        // Status is already filtered in the query, so return all
        dataController.coEquipRequests
    }

    var body: some View {
        ZStack {
            if isLoading {
                ProgressView()
            } else if pendingRequests.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "tray.fill")
                        .font(.system(size: 64))
                        .foregroundColor(.secondary)
                    VStack(spacing: 8) {
                        Text("No Co-Equip requests")
                            .font(.title3)
                            .fontWeight(.semibold)
                        Text("New Co-Equip booking requests will appear here")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(pendingRequests, id: \.id) { request in
                            CoEquipRequestRow(request: request)
                                .padding(.vertical, 8)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical)
                }
                .refreshable {
                    await refreshData()
                }
            }
        }
        .background(Color(.systemGray6).ignoresSafeArea())
        .navigationTitle("Co-Equip Requests")
        .navigationBarTitleDisplayMode(.inline)
        .task(id: dataController.currentUser?.id) {
            loadTask?.cancel()

            loadTask = Task {
                await loadData()
            }
        }
        .onDisappear {
            loadTask?.cancel()
        }
    }

    private func loadData() async {
        guard !Task.isCancelled else { return }

        if dataController.coEquipRequests.isEmpty {
            isLoading = true
        }

        do {
            try await dataController.fetchCoEquipRequests()
        } catch {
            if !Task.isCancelled {
                print("Error fetching Co-Equip requests: \(error)")
            }
        }
        isLoading = false
    }

    private func refreshData() async {
        isLoading = true
        do {
            try await dataController.fetchCoEquipRequests()
        } catch {
            print("Error refreshing Co-Equip requests: \(error)")
        }
        isLoading = false
    }
}

struct CoEquipRequestRow: View {
    @EnvironmentObject var dataController: DataController
    @Environment(\.colorScheme) var colorScheme
    let request: DataController.CoEquipRequest
    @State private var equipmentName: String = "Loading..."
    @State private var equipmentImage: String?
    @State private var customerName: String = "Loading..."
    @State private var participantCount: Int = 0

    private var timeSlotText: String {
        request.timeSlot.capitalized
    }

    private var timeSlotColor: Color {
        switch request.timeSlot.lowercased() {
        case "morning":
            return .orange
        case "afternoon":
            return .yellow
        case "evening":
            return .indigo
        default:
            return .blue
        }
    }

    private var formattedDate: String {
        guard let date = request.date else {
            return request.requestedDate
        }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with Equipment Image and Details
            HStack(spacing: 12) {
                if let imageUrl = equipmentImage, let url = URL(string: imageUrl) {
                    WebImage(url: url)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(.systemGray5), lineWidth: 1)
                        )
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.1))
                        .frame(width: 80, height: 80)
                        .overlay(
                            Image(systemName: "photo")
                                .foregroundColor(.gray)
                        )
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(equipmentName)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    Text("Requested by: \(customerName)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)

                    HStack(spacing: 4) {
                        Image(systemName: "person.2.fill")
                            .font(.caption2)
                        Text("\(participantCount) farmers")
                            .font(.caption)
                    }
                    .foregroundColor(.purple)
                }
                Spacer()
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
                            Text(formattedDate)
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

                // Area and Location Row
                HStack(spacing: 12) {
                    // Area
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

                    // Time Period
                    if let timePeriod = request.timePeriod {
                        HStack(spacing: 6) {
                            Image(systemName: "timer")
                                .font(.subheadline)
                                .foregroundColor(.orange)
                                .frame(width: 20)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Duration")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                Text(timePeriod)
                                    .font(.subheadline.weight(.medium))
                                    .foregroundColor(.primary)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                // Location Row
                HStack(spacing: 6) {
                    Image(systemName: "location.fill")
                        .font(.subheadline)
                        .foregroundColor(.red)
                        .frame(width: 20)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Location")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(request.location)
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.primary)
                            .lineLimit(2)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Divider()

                // Status Badge
                HStack(spacing: 12) {
                    HStack(spacing: 6) {
                        Image(systemName: "clock.badge.exclamationmark")
                            .font(.caption)
                        Text("Awaiting Your Response")
                            .font(.footnote.weight(.semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.orange)
                    .clipShape(Capsule())
                    .shadow(color: Color.orange.opacity(0.3), radius: 4, x: 0, y: 2)

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
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
        .task {
            await loadRequestDetails()
        }
    }

    private func loadRequestDetails() async {
        // Fetch equipment details from cache
        if let equipmentId = request.equipmentId,
           let equipment = dataController.equipmentDetails[equipmentId] {
            await MainActor.run {
                equipmentName = equipment.name
                equipmentImage = equipment.equipmentImage
            }
        } else {
            await MainActor.run {
                equipmentName = "Unknown Equipment"
            }
        }

        // Fetch customer name
        if let userId = request.userId {
            do {
                let name = try await dataController.fetchUserName(userId: userId)
                await MainActor.run {
                    customerName = name
                }
            } catch {
                print("Error fetching customer: \(error)")
                await MainActor.run {
                    customerName = "Unknown Customer"
                }
            }
        }

        // Get participant count
        do {
            let count = try await dataController.fetchParticipantCount(requestId: request.id)
            await MainActor.run {
                participantCount = count
            }
        } catch {
            print("Error fetching participant count: \(error)")
            await MainActor.run {
                participantCount = 1
            }
        }
    }

    private func openInMaps() {
        let destination = request.location
        let encodedDestination = destination.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""

        if let url = URL(string: "maps://?daddr=\(encodedDestination)&dirflg=d") {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            } else {
                if let webUrl = URL(string: "https://maps.apple.com/?daddr=\(encodedDestination)&dirflg=d") {
                    UIApplication.shared.open(webUrl, options: [:], completionHandler: nil)
                }
            }
        }
    }
}
