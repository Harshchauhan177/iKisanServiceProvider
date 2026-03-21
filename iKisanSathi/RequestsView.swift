import SwiftUI
import SDWebImageSwiftUI

struct RequestsView: View {
    @EnvironmentObject var dataController: DataController
    @State private var isLoading = true
    @State private var selectedRequestType = 0 // 0 for Individual, 1 for Co-Equip
    @State private var loadTask: Task<Void, Never>? = nil
    @State private var errorMessage: String?
    @State private var showError = false
    
    var filteredRequests: [Request] {
        var requests: [Request] = []

        switch selectedRequestType {
        case 0:
            // Individual requests - exclude Co-Equip
            requests = dataController.producerRequests.filter { $0.type != .coEquip }
        case 1:
            // Co-Equip requests - include from both sources
            // First, get Co-Equip requests from producerRequests
            let producerCoEquipRequests = dataController.producerRequests.filter { $0.type == .coEquip }
            requests.append(contentsOf: producerCoEquipRequests)

            // Then, convert and add Co-Equip requests from coEquipRequests
            let convertedCoEquipRequests = dataController.coEquipRequests.compactMap { coEquipRequest -> Request? in
                // Convert CoEquipRequest to Request
                guard let userId = coEquipRequest.userId,
                      let equipmentId = coEquipRequest.equipmentId else {
                    return nil
                }

                // Convert string values back to enums
                let timeSlot: TimeSlot
                switch coEquipRequest.timeSlot.lowercased() {
                case "morning": timeSlot = .morning
                case "afternoon": timeSlot = .afternoon
                case "evening": timeSlot = .evening
                default: timeSlot = .morning
                }

                let requestType: RequestType
                switch coEquipRequest.typeOfRequest.lowercased() {
                case "myrequest": requestType = .myRequest
                case "acceptedrequest": requestType = .joinedRequest
                default: requestType = .myRequest
                }

                // Create Request from CoEquipRequest
                return Request(
                    id: coEquipRequest.id,
                    userId: userId,
                    equipmentId: equipmentId,
                    requestedDate: coEquipRequest.requestedDate,
                    status: .pending, // CoEquipRequest status is stored as string "Pending"
                    type: .coEquip,
                    area: coEquipRequest.area,
                    timeSlot: timeSlot,
                    timePeriod: coEquipRequest.timePeriod,
                    location: coEquipRequest.location,
                    typeOfRequest: requestType
                )
            }
            requests.append(contentsOf: convertedCoEquipRequests)

        default:
            break
        }

        return requests
    }
    
    var filteredBookings: [Booking] {
        // Include bookings in both Individual and Co-Equip segments
        return dataController.producerBookings
    }
    
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
            
            VStack(spacing: 0) {
                // Segmented Control
                Picker("", selection: $selectedRequestType) {
                    Text("Individual").tag(0)
                    Text("Co-Equip").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                if isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("Loading requests...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if (selectedRequestType == 0 && filteredRequests.isEmpty && filteredBookings.isEmpty) ||
                          (selectedRequestType == 1 && filteredRequests.isEmpty) {
                    VStack(spacing: 20) {
                        Image(systemName: selectedRequestType == 0 ? "person.slash" : "person.2.slash")
                            .font(.system(size: 64))
                            .foregroundColor(.secondary)
                        
                        VStack(spacing: 8) {
                            Text("No \(selectedRequestType == 0 ? "Individual" : "Co-Equip") Requests")
                                .font(.title3.weight(.semibold))
                                .foregroundColor(.primary)
                            
                            Text("New requests will appear here")
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            if selectedRequestType == 0 {
                                // Show Individual requests (non-CoEquip)
                                ForEach(filteredRequests) { request in
                                    RequestRow(request: request, equipment: dataController.equipmentDetails[request.equipmentId ?? UUID()])
                                        .padding(.horizontal)
                                }
                                // Show bookings under Individual
                                ForEach(filteredBookings) { booking in
                                    BookingRow(booking: booking, equipment: dataController.equipmentDetails[booking.equipmentId ?? UUID()])
                                        .padding(.horizontal)
                                }
                            } else {
                                // Show Co-Equip requests
                                ForEach(filteredRequests) { request in
                                    RequestRow(request: request, equipment: dataController.equipmentDetails[request.equipmentId ?? UUID()])
                                        .padding(.horizontal)
                                }
                                // Also show bookings under Co-Equip
                                ForEach(filteredBookings) { booking in
                                    BookingRow(booking: booking, equipment: dataController.equipmentDetails[booking.equipmentId ?? UUID()])
                                        .padding(.horizontal)
                                }
                            }
                        }
                        .padding(.vertical)
                    }
                    .refreshable {
                        await refreshData()
                    }
                }
            }
        }
        .navigationTitle("New Requests")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Error Loading Data", isPresented: $showError) {
            Button("OK", role: .cancel) { }
            Button("Retry") {
                Task {
                    await loadData()
                }
            }
        } message: {
            if let errorMessage = errorMessage {
                Text(errorMessage)
            }
        }
        .task(id: dataController.currentUser?.id) {
            // Cancel previous load task if it exists
            loadTask?.cancel()
            
            // Only load if not already loaded or if user changed
            loadTask = Task {
                isLoading = true
                await loadData()
                isLoading = false
            }
        }
        .onDisappear {
            // Clean up task when view disappears to prevent unnecessary work
            loadTask?.cancel()
        }
    }
    
    private func loadData() async {
        // Check if task was cancelled before proceeding
        guard !Task.isCancelled else { return }

        do {
            // Always fetch equipment and requests first
            try await dataController.fetchProducerEquipmentAndRequests()

            // Check again before second fetch
            guard !Task.isCancelled else { return }

            // Always fetch bookings to ensure they appear
            try await dataController.fetchBookings()

            // Check again before third fetch
            guard !Task.isCancelled else { return }

            // Fetch Co-Equip requests
            try await dataController.fetchCoEquipRequests()

            // Clear any previous errors on success
            await MainActor.run {
                errorMessage = nil
                showError = false
            }
        } catch {
            // Only show error if not cancelled
            if !Task.isCancelled {
                await MainActor.run {
                    errorMessage = "Unable to load requests. Please check your connection and try again."
                    showError = true
                }
                print("Error fetching data: \(error)")
            }
        }
    }
    
    private func refreshData() async {
        do {
            try await dataController.refreshAllData()
        } catch {
            print("Error refreshing data: \(error)")
        }
    }
}

struct RequestRow: View {
    let request: Request
    let equipment: DataController.Equipment?
    @EnvironmentObject var dataController: DataController
    @State private var isPressed = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showingEditSheet = false
    @State private var participantCount: Int = 0
    @State private var participants: [DataController.CoEquipParticipant] = []
    @State private var showParticipants: Bool = false
    @State private var customerName: String = "Loading..."

    // Check if this request is being processed
    private var isProcessing: Bool {
        dataController.processingRequests.contains(request.id)
    }

    // Helper to get time slot display name
    private var timeSlotText: String {
        switch request.timeSlot {
        case .morning:
            return "Morning"
        case .afternoon:
            return "Afternoon"
        case .evening:
            return "Evening"
        }
    }

    // Helper to get time slot color
    private var timeSlotColor: Color {
        switch request.timeSlot {
        case .morning:
            return .orange
        case .afternoon:
            return .yellow
        case .evening:
            return .indigo
        }
    }

    private func calculateTotalArea() -> Double {
        let participantAreas = participants.reduce(0.0) { $0 + $1.area }
        return request.area + participantAreas
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

                        if request.type == .coEquip {
                            // For Co-Equip: Show tappable participant count
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
                        } else {
                            // For Individual: Show capacity
                            HStack(spacing: 4) {
                                Image(systemName: "scalemass")
                                    .font(.caption2)
                                Text(equipment.capacity)
                                    .font(.caption)
                            }
                            .foregroundColor(.secondary)
                        }
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
                            if let date = request.date {
                                Text(date, style: .date)
                                    .font(.subheadline.weight(.medium))
                                    .foregroundColor(.primary)
                            }
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
                    // Area (show total for Co-Equip)
                    HStack(spacing: 6) {
                        Image(systemName: "map")
                            .font(.subheadline)
                            .foregroundColor(.green)
                            .frame(width: 20)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(request.type == .coEquip ? "Total Area" : "Area")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text("\(String(format: "%.1f", request.type == .coEquip ? calculateTotalArea() : request.area)) acres")
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(.primary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    // Request Type Badge - aligned to match Time Slot position
                    HStack(spacing: 6) {
                        Spacer()
                        HStack(spacing: 6) {
                            Image(systemName: request.type == .coEquip ? "person.2.fill" : "person.fill")
                                .font(.caption)
                            Text(request.type == .coEquip ? "Co-Equip" : "Individual")
                                .font(.caption.weight(.semibold))
                        }
                        .foregroundColor(request.type == .coEquip ? .purple : .blue)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background((request.type == .coEquip ? Color.purple : Color.blue).opacity(0.15))
                        .clipShape(Capsule())
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }

                // Expandable Participants Section (for Co-Equip only)
                if request.type == .coEquip && showParticipants {
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

                // Location Button
                Button(action: {
                    openInMaps()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "map.fill")
                            .font(.caption)
                        Text("View Location")
                            .font(.subheadline.weight(.medium))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .foregroundColor(.white)
                    .background(Color.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .accessibilityLabel("View location in Maps")
                .accessibilityHint("Opens Apple Maps with directions to the request location")

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
                    .accessibilityLabel(isProcessing ? "Processing request" : "Accept request")
                    .accessibilityHint(isProcessing ? "" : "Accept this service request")
                    
                    // Delete Button
                    Button(action: {
                        Task {
                            await handleDeleteRequest()
                        }
                    }) {
                        HStack(spacing: 8) {
                            if isProcessing {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "trash.fill")
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
                    .accessibilityLabel(isProcessing ? "Processing request" : "Decline request")
                    .accessibilityHint(isProcessing ? "" : "Decline this service request")
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 4)
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
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .sheet(isPresented: $showingEditSheet) {
            if let equipment = equipment {
                EditEquipmentView(equipment: equipment)
            }
        }
        .task {
            // Load participant data for Co-Equip requests
            if request.type == .coEquip {
                await loadCoEquipDetails()
            }
        }
    }

    private func loadCoEquipDetails() async {
        // Fetch customer name
        if let userId = request.userId {
            do {
                let name = try await dataController.fetchUserName(userId: userId)
                await MainActor.run {
                    customerName = name
                }
            } catch {
                print("Error fetching customer name: \(error)")
                await MainActor.run {
                    customerName = "Unknown"
                }
            }
        }

        // Fetch participant count
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
            await MainActor.run {
                participants = fetchedParticipants
            }
        } catch {
            print("Error fetching participants: \(error)")
        }
    }

    private func handleAcceptRequest() async {
        do {
            try await dataController.acceptRequest(request)
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    private func handleDeleteRequest() async {
        do {
            try await dataController.deleteRequest(request)
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    // Function to open Apple Maps with directions
    private func openInMaps() {
        let destination = request.location
        
        // Create URL for Apple Maps with directions
        let encodedDestination = destination.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
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
}

struct BookingRow: View {
    let booking: Booking
    let equipment: DataController.Equipment?
    @EnvironmentObject var dataController: DataController
    @State private var isPressed = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showingEditSheet = false
    
    // Check if this booking is being processed
    private var isProcessing: Bool {
        dataController.processingBookings.contains(booking.id)
    }
    
    // Helper to get time slot display name
    private var timeSlotText: String {
        switch booking.timeSlot {
        case .morning:
            return "Morning"
        case .afternoon:
            return "Afternoon"
        case .evening:
            return "Evening"
        }
    }
    
    // Helper to get time slot color
    private var timeSlotColor: Color {
        switch booking.timeSlot {
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
            
            // Booking Details Grid
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
                            Text(booking.bookingDate, style: .date)
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
                    HStack(spacing: 6) {
                        Image(systemName: "map")
                            .font(.subheadline)
                            .foregroundColor(.green)
                            .frame(width: 20)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Area")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text("\(String(format: "%.1f", booking.fieldArea)) acres")
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(.primary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Booking Type Badge - aligned to match Time Slot position
                    HStack(spacing: 6) {
                        Spacer()
                        HStack(spacing: 6) {
                            Image(systemName: "person.fill")
                                .font(.caption)
                            Text("Individual")
                                .font(.caption.weight(.semibold))
                        }
                        .foregroundColor(.blue)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.15))
                        .clipShape(Capsule())
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
                
                Divider()
                
                // Location Button
                Button(action: {
                    openInMapsForBooking()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "map.fill")
                            .font(.caption)
                        Text("View Location")
                            .font(.subheadline.weight(.medium))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .foregroundColor(.white)
                    .background(Color.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .accessibilityLabel("View location in Maps")
                .accessibilityHint("Opens Apple Maps with directions to the booking location")
                
                Divider()
                
                // Action Buttons
                HStack(spacing: 12) {
                    // Accept Button
                    Button(action: {
                        Task {
                            await handleAcceptBooking()
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
                    .accessibilityLabel(isProcessing ? "Processing booking" : "Accept booking")
                    .accessibilityHint(isProcessing ? "" : "Accept this booking request")
                    
                    // Delete Button
                    Button(action: {
                        Task {
                            await handleDeleteBooking()
                        }
                    }) {
                        HStack(spacing: 8) {
                            if isProcessing {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "trash.fill")
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
                    .accessibilityLabel(isProcessing ? "Processing booking" : "Decline booking")
                    .accessibilityHint(isProcessing ? "" : "Decline this booking request")
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 4)
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
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .sheet(isPresented: $showingEditSheet) {
            if let equipment = equipment {
                EditEquipmentView(equipment: equipment)
            }
        }
    }
    
    private func handleAcceptBooking() async {
        do {
            try await dataController.acceptBookingTapped(booking)
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    private func handleDeleteBooking() async {
        do {
            try await dataController.deleteBooking(booking)
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    // Function to open Apple Maps with directions
    private func openInMapsForBooking() {
        // Check if we have coordinates first (more accurate)
        if let lat = booking.latitude, let lon = booking.longitude {
            // Use coordinates for precise location
            if let url = URL(string: "maps://?daddr=\(lat),\(lon)&dirflg=d") {
                if UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                    return
                } else {
                    // Fallback to web-based Apple Maps with coordinates
                    if let webUrl = URL(string: "https://maps.apple.com/?daddr=\(lat),\(lon)&dirflg=d") {
                        UIApplication.shared.open(webUrl, options: [:], completionHandler: nil)
                        return
                    }
                }
            }
        }
        
        // Fallback to address if coordinates not available
        if let address = booking.address {
            let encodedDestination = address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
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
}
