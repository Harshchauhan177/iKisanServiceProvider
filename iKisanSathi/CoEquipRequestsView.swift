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
    @State private var participants: [DataController.CoEquipParticipant] = []
    @State private var showParticipants: Bool = false
    @State private var showError = false
    @State private var errorMessage = ""

    // Check if this request is being processed
    private var isProcessing: Bool {
        dataController.processingRequests.contains(request.id)
    }

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

                    // Tappable participant count to show details
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showParticipants.toggle()
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "person.2.fill")
                                .font(.caption2)
                            Text("\(participantCount) farmers")
                                .font(.caption)
                            Image(systemName: "chevron.right")
                                .font(.caption2)
                                .rotationEffect(.degrees(showParticipants ? 90 : 0))
                                .animation(.easeInOut, value: showParticipants)
                        }
                        .foregroundColor(.purple)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(participantCount) farmers")
                    .accessibilityHint("Expands to show individual farmer details")
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
                    // Total Area
                    HStack(spacing: 6) {
                        Image(systemName: "map")
                            .font(.subheadline)
                            .foregroundColor(.green)
                            .frame(width: 20)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Total Area")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text("\(String(format: "%.1f", calculateTotalArea())) acres")
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

                // Expandable Participants Section
                if showParticipants {
                    VStack(alignment: .leading, spacing: 0) {
                        // Request Creator
                        FarmerRowView(
                            name: customerName,
                            area: request.area,
                            timeSlot: timeSlotText,
                            isCreator: true
                        )

                        // Participating Farmers
                        if !participants.isEmpty {
                            ForEach(Array(participants.enumerated()), id: \.element.id) { index, participant in
                                Divider()
                                    .padding(.horizontal, 12)

                                FarmerRowView(
                                    name: participant.userName ?? "Farmer",
                                    area: participant.area,
                                    timeSlot: participant.timeSlot?.capitalized ?? timeSlotText,
                                    isCreator: false
                                )
                            }
                        }
                    }
                    .background(Color(uiColor: .secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }

                Divider()

                // Directions Button
                Button(action: {
                    openInMaps()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "map.fill")
                            .font(.caption)
                        Text("Get Directions")
                            .font(.subheadline.weight(.medium))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .foregroundColor(.white)
                    .background(Color.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                Divider()

                // Action Buttons
                HStack(spacing: 12) {
                    // Accept Button
                    Button(action: {
                        Task {
                            await handleAcceptRequest()
                        }
                    }) {
                        HStack(spacing: 8) {
                            if isProcessing {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.subheadline)
                            }
                            Text(isProcessing ? "Processing..." : "Accept")
                                .font(.subheadline.weight(.semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(isProcessing ? Color.gray : Color.green)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(color: (isProcessing ? Color.gray : Color.green).opacity(0.3), radius: 4, x: 0, y: 2)
                    }
                    .disabled(isProcessing)
                    .accessibilityLabel(isProcessing ? "Processing request" : "Accept Co-Equip request")
                    .accessibilityHint(isProcessing ? "" : "Accept this Co-Equip service request")

                    // Decline Button
                    Button(action: {
                        Task {
                            await handleDeclineRequest()
                        }
                    }) {
                        HStack(spacing: 8) {
                            if isProcessing {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.subheadline)
                            }
                            Text(isProcessing ? "Processing..." : "Decline")
                                .font(.subheadline.weight(.semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(isProcessing ? Color.gray : Color.red)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(color: (isProcessing ? Color.gray : Color.red).opacity(0.3), radius: 4, x: 0, y: 2)
                    }
                    .disabled(isProcessing)
                    .accessibilityLabel(isProcessing ? "Processing request" : "Decline Co-Equip request")
                    .accessibilityHint(isProcessing ? "" : "Decline this Co-Equip service request")
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
        .overlay(Group {
            if isProcessing {
                Color.black.opacity(0.1)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        })
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
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

        // Fetch participants details
        do {
            let fetchedParticipants = try await dataController.fetchParticipants(requestId: request.id)
            #if DEBUG
            print("📋 Fetched \(fetchedParticipants.count) joined participants for request \(request.id)")
            #endif
            await MainActor.run {
                participants = fetchedParticipants
            }
        } catch {
            print("❌ Error fetching participants: \(error)")
            #if DEBUG
            if let decodingError = error as? DecodingError {
                switch decodingError {
                case .keyNotFound(let key, let context):
                    print("   Key '\(key.stringValue)' not found: \(context.debugDescription)")
                case .typeMismatch(let type, let context):
                    print("   Type mismatch for type \(type): \(context.debugDescription)")
                case .valueNotFound(let type, let context):
                    print("   Value not found for type \(type): \(context.debugDescription)")
                case .dataCorrupted(let context):
                    print("   Data corrupted: \(context.debugDescription)")
                @unknown default:
                    print("   Unknown decoding error")
                }
            }
            #endif
        }
    }

    private func handleAcceptRequest() async {
        do {
            try await dataController.acceptCoEquipRequest(request)
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }

    private func handleDeclineRequest() async {
        do {
            try await dataController.declineCoEquipRequest(request)
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }

    private func calculateTotalArea() -> Double {
        // Sum of request creator's area and all participants' areas
        let participantAreas = participants.reduce(0.0) { $0 + $1.area }
        return request.area + participantAreas
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

// MARK: - Farmer Row View
struct FarmerRowView: View {
    let name: String
    let area: Double
    let timeSlot: String
    let isCreator: Bool

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            // Leading: Name and Area
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(name)
                        .font(.subheadline)
                        .bold()
                        .foregroundColor(.primary)
                    if isCreator {
                        Text("(Creator)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                Text("\(String(format: "%.1f", area)) acres")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Trailing: Time Slot
            Text(timeSlot)
                .font(.caption2)
                .foregroundColor(Color(uiColor: .tertiaryLabel))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(name), \(String(format: "%.1f", area)) acres, \(timeSlot)")
    }
}
