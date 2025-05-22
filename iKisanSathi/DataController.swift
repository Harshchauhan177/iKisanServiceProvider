import Foundation
import Supabase

enum AuthError: Error, LocalizedError {
    case otpNotVerified
    case invalidEmail
    case invalidCredentials
    
    var errorDescription: String? {
        switch self {
        case .otpNotVerified:
            return "Please verify your email with OTP first"
        case .invalidEmail:
            return "Invalid email address"
        case .invalidCredentials:
            return "Invalid credentials"
        }
    }
}


class DataController: ObservableObject {
    // Shared URLSession for all network requests
    private static let sharedSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.waitsForConnectivity = true
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 300
        
        // Set proper TLS security
        config.tlsMinimumSupportedProtocolVersion = .TLSv12
        config.tlsMaximumSupportedProtocolVersion = .TLSv13
        
        // Enable all security features
        config.httpShouldSetCookies = true
        config.httpCookieAcceptPolicy = .always
        config.httpShouldUsePipelining = true
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        
        return URLSession(configuration: config)
    }()
    
    private lazy var supabase: SupabaseClient = {
        return SupabaseClient(
            supabaseURL: URL(string: "https://pxuuupiqeipyemluyers.supabase.co")!,
            supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InB4dXV1cGlxZWlweWVtbHV5ZXJzIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc0NTMwNTMzNCwiZXhwIjoyMDYwODgxMzM0fQ.KGIxp5mM10AyHoCFNV0uJNanFqw7AqH8MXrwmFTNSCI"
        )
    }()
    
    @Published var isAuthenticated = false {
        didSet {
            // Whenever authentication state changes, update UserDefaults
            UserDefaults.standard.set(isAuthenticated, forKey: "isAuthenticated")
        }
    }
    @Published var currentUser: User?
    @Published var isOTPSent = false
    @Published var isOTPVerified = false
    @Published var tempEmail: String?
    
    private let accessTokenKey = "supabase_access_token"
    private let refreshTokenKey = "supabase_refresh_token"
    private let userKey = "current_user"
    private var sessionRestoreRetryCount = 0
    private let maxSessionRestoreRetries = 3
    private let retryDelayBase: UInt64 = 1_000_000_000 // 1 second in nanoseconds
    
    init() {
        // Check if user was previously authenticated
        isAuthenticated = UserDefaults.standard.bool(forKey: "isAuthenticated")
        
        // Try to restore the current user
        if let userData = UserDefaults.standard.data(forKey: userKey),
           let user = try? JSONDecoder().decode(User.self, from: userData) {
            self.currentUser = user
        }
        
        // If we have a stored session, try to restore it
        if isAuthenticated {
            Task {
                await restoreSession()
            }
        }
    }
    
    private func restoreSession() async {
        print("🔄 Attempting to restore session...")
        
        guard sessionRestoreRetryCount < maxSessionRestoreRetries else {
            print("⚠️ Maximum session restore retries reached")
            clearStoredSession()
            return
        }
        
        guard let accessToken = UserDefaults.standard.string(forKey: accessTokenKey),
              let refreshToken = UserDefaults.standard.string(forKey: refreshTokenKey) else {
            print("ℹ️ No stored tokens found")
            DispatchQueue.main.async {
                self.isAuthenticated = false
            }
            return
        }
        
        print("🔑 Found stored tokens, attempting to restore session...")
        
        do {
            // Exponential backoff delay
            if sessionRestoreRetryCount > 0 {
                let delay = retryDelayBase * UInt64(pow(2.0, Double(sessionRestoreRetryCount - 1)))
                try await Task.sleep(nanoseconds: delay)
            }
            
            // Try to restore session
            try await supabase.auth.setSession(accessToken: accessToken, refreshToken: refreshToken)
            
            // Verify session is valid
            if let session = supabase.auth.currentSession {
                print("✅ Session restored successfully")
                
                // Fetch user data
                try await fetchProducerDetails()
                try await fetchProducerEquipmentAndRequests()
                
                // Reset retry count on success
                sessionRestoreRetryCount = 0
                print("✅ Session and user data restored successfully")
            } else {
                throw NSError(domain: "Session", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid session"])
            }
        } catch {
            print("⚠️ Error restoring session (attempt \(sessionRestoreRetryCount + 1)): \(error)")
            sessionRestoreRetryCount += 1
            
            // If it's a network error, retry
            if (error as NSError).domain == NSURLErrorDomain {
                await restoreSession()
            } else {
                // For other errors, clear the session
                clearStoredSession()
            }
        }
    }
    
    private func clearStoredSession() {
        print("🧹 Clearing stored session...")
        UserDefaults.standard.removeObject(forKey: accessTokenKey)
        UserDefaults.standard.removeObject(forKey: refreshTokenKey)
        UserDefaults.standard.removeObject(forKey: userKey)
        UserDefaults.standard.removeObject(forKey: "isAuthenticated")
        
        DispatchQueue.main.async {
            self.isAuthenticated = false
            self.currentUser = nil
            self.currentProducer = nil
        }
    }
    
    struct User: Codable {
        let id: UUID
        let email: String
        let createdAt: Date
    }
    
    struct Equipment: Codable {
        let equipmentID: UUID
        let equipmentImage: String
        var name: String
        var type: String
        var capacity: String
        let availabilityStartDate: String
        let availabilityEndDate: String
        var pricePerHour: Double
        let realPricePerHour: Double
        var pricePerAcre: Double
        let realPricePerAcre: Double
        let providerID: UUID
        let rating: Double
        var location: String
        let coEquipDetail: coEquipState
        var modelYear: String
        var mielage: String
        var description: String?
        let isRecommended: Bool
        let providerName: String
        let preBookingStatus: String?
        
        var startDate: Date? {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
            return formatter.date(from: availabilityStartDate)
        }
        
        var endDate: Date? {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
            return formatter.date(from: availabilityEndDate)
        }
        
        enum CodingKeys: String, CodingKey {
            case equipmentID = "equipmentID"
            case equipmentImage
            case name
            case type
            case capacity
            case availabilityStartDate
            case availabilityEndDate
            case pricePerHour
            case realPricePerHour
            case pricePerAcre
            case realPricePerAcre
            case providerID
            case rating
            case location
            case coEquipDetail
            case modelYear
            case mielage
            case description
            case isRecommended
            case providerName
            case preBookingStatus
        }
    }
    
    struct Producer: Codable {
        let id: String
        let email: String
        let name: String
        let phone: String?
        let location: String?
        let rating: Double?
        let profileimage: String?
        let equipments: [Equipment]?
        let accountNo: String?
        let ifcsCode: String?
    }
    
    @Published var currentProducer: Producer?
    
    func fetchProducerDetails() async throws {
        guard let currentUser = currentUser else { return }
        
        let response = try await supabase.database
            .from("producer")
            .select()
            .eq("id", value: currentUser.id.uuidString)
            .single()
            .execute()
        
        let producer = try JSONDecoder().decode(Producer.self, from: response.data)
        
        DispatchQueue.main.async {
            self.currentProducer = producer
        }
    }
    
    func sendOTP(email: String, name: String, password: String) async throws {
        // Store details for later use after OTP verification
        tempEmail = email
        UserDefaults.standard.set(name, forKey: "tempName")
        UserDefaults.standard.set(password, forKey: "tempPassword")
        
        // Send OTP via Supabase Auth
        try await supabase.auth.signUp(email: email, password: password)
        DispatchQueue.main.async {
            self.isOTPSent = true
            self.tempEmail = email
        }
    }
    
    func verifyOTP(otp: String) async throws {
        guard let email = tempEmail else { throw AuthError.invalidEmail }
        
        // Verify OTP
        try await supabase.auth.verifyOTP(
            email: email,
            token: otp,
            type: .email
        )
        
        DispatchQueue.main.async {
            self.isOTPVerified = true
        }
    }
    
    func completeSignUp() async throws {
        guard isOTPVerified else { throw AuthError.otpNotVerified }
        guard let email = tempEmail,
              let password = UserDefaults.standard.string(forKey: "tempPassword"),
              let name = UserDefaults.standard.string(forKey: "tempName") else {
            throw AuthError.invalidCredentials
        }
        
        // Sign in instead of signing up again
        let authResponse = try await supabase.auth.signIn(email: email, password: password)
        
        // Insert producer record into "producer" table
        let producer = Producer(
            id: authResponse.user.id.uuidString,
            email: email,
            name: name,
            phone: nil,
            location: nil,
            rating: nil,
            profileimage: nil,
            equipments: nil,
            accountNo: nil,
            ifcsCode: nil
        )
        
        try await supabase.database
            .from("producer")
            .insert(producer)
            .execute()
        
        DispatchQueue.main.async {
            self.isOTPVerified = false
            self.isOTPSent = false
            self.tempEmail = nil
            UserDefaults.standard.removeObject(forKey: "tempName")
            UserDefaults.standard.removeObject(forKey: "tempPassword")
        }
    }
    
    func signIn(email: String, password: String) async throws {
        print("🔑 Attempting sign in...")
        let authResponse = try await supabase.auth.signIn(email: email, password: password)
        
        // Store tokens
        if let session = supabase.auth.currentSession {
            print("📝 Storing session tokens...")
            UserDefaults.standard.set(session.accessToken, forKey: accessTokenKey)
            UserDefaults.standard.set(session.refreshToken, forKey: refreshTokenKey)
            
            // Store user data
            let userData = try JSONEncoder().encode(User(
                id: authResponse.user.id,
                email: authResponse.user.email ?? "",
                createdAt: authResponse.user.createdAt
            ))
            UserDefaults.standard.set(userData, forKey: userKey)
            print("✅ Session tokens stored successfully")
        }
        
        // Set current user
        let user = User(
            id: authResponse.user.id,
            email: authResponse.user.email ?? "",
            createdAt: authResponse.user.createdAt
        )
        
        print("👤 Fetching producer details...")
        // Fetch producer details
        let producerResponse = try await supabase.database
            .from("producer")
            .select()
            .eq("id", value: user.id.uuidString)
            .single()
            .execute()
        
        let producer = try JSONDecoder().decode(Producer.self, from: producerResponse.data)
        
        // Update UI on main thread
        DispatchQueue.main.async {
            self.currentUser = user
            self.currentProducer = producer
            self.isAuthenticated = true
        }
        
        print("✅ Sign in successful")
    }
    
    func signOut() async throws {
        print("🚪 Signing out...")
        // Clear Supabase session
        try await supabase.auth.signOut()
        
        // Reset all auth states
        DispatchQueue.main.async {
            self.isAuthenticated = false
            self.currentUser = nil
            self.currentProducer = nil
            self.isOTPSent = false
            self.isOTPVerified = false
            self.tempEmail = nil
            self.equipmentDetails = [:]
            self.producerEquipment = []
            self.producerRequests = []
        }
        
        // Clear stored session
        clearStoredSession()
        print("✅ Sign out complete")
    }
    
    func checkSession() async {
        print("🔐 Checking session...")
        if let session = supabase.auth.currentSession {
            // Valid session exists
            let user = session.user
            
            do {
                print("📱 Found existing session, fetching user details...")
                // Fetch producer details
                let producerResponse = try await supabase.database
                    .from("producer")
                    .select()
                    .eq("id", value: user.id.uuidString)
                    .single()
                    .execute()
                
                let producer = try JSONDecoder().decode(Producer.self, from: producerResponse.data)
                
                // Update UI on main thread
                DispatchQueue.main.async {
                    self.currentUser = User(
                        id: user.id,
                        email: user.email ?? "",
                        createdAt: user.createdAt
                    )
                    self.currentProducer = producer
                    self.isAuthenticated = true
                }
                
                // Fetch additional data
                try await fetchProducerEquipmentAndRequests()
                print("✅ Session restored successfully")
            } catch {
                print("⚠️ Error restoring session: \(error)")
                // Session is invalid or there was an error
                try? await signOut()
            }
        } else {
            print("ℹ️ No active session found")
            // No active session
            DispatchQueue.main.async {
                self.currentUser = nil
                self.isAuthenticated = false
            }
        }
    }
    
    func addEquipment(_ equipment: Equipment) async throws {
        try await supabase.database
            .from("equipment")
            .insert(equipment)
            .execute()
    }
    
    @Published var producerRequests: [Request] = []
    @Published var producerEquipment: [Equipment] = []
    @Published var equipmentDetails: [UUID: Equipment] = [:]
    
    func fetchProducerEquipmentAndRequests() async throws {
        guard let currentUser = currentUser else {
            print("⚠️ No current user found")
            throw NSError(domain: "DataController", code: 1, userInfo: [NSLocalizedDescriptionKey: "No user logged in"])
        }
        
        print("🔍 Fetching equipment for user: \(currentUser.id)")
        
        // First get all equipment for current producer
        let equipmentResponse = try await supabase.database
            .from("equipment")
            .select()
            .eq("providerID", value: currentUser.id.uuidString)
            .order("name")  // Order by name for consistent display
            .execute()
        
        print("📦 Equipment response data: \(String(data: equipmentResponse.data, encoding: .utf8) ?? "nil")")
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        do {
            let equipment = try decoder.decode([Equipment].self, from: equipmentResponse.data)
            print("🚜 Found \(equipment.count) equipment items")
            
            // Create a lookup dictionary for equipment details
            var equipmentDict: [UUID: Equipment] = [:]
            let equipmentIds: [String] = equipment.map { equip in
                equipmentDict[equip.equipmentID] = equip
                return equip.equipmentID.uuidString
            }
            
            print("🔑 Equipment IDs: \(equipmentIds)")
            
            // Then fetch all requests for equipment owned by this producer
            if !equipmentIds.isEmpty {
                print("📥 Fetching requests for equipment IDs")
                let requestsResponse = try await supabase.database
                    .from("requests")
                    .select()
                    .in("equipmentId", values: equipmentIds)
                    .eq("status", value: "Pending")  // Only fetch pending requests
                    .execute()
                
                print("📬 Requests response data: \(String(data: requestsResponse.data, encoding: .utf8) ?? "nil")")
                
                let requests = try decoder.decode([Request].self, from: requestsResponse.data)
                print("📝 Found \(requests.count) total requests")
                
                // Filter requests to only include those for this producer's equipment
                let producerRequests = requests.filter { request in
                    guard let equipmentId = request.equipmentId else {
                        print("⚠️ Request has no equipment ID")
                        return false
                    }
                    return equipmentDict[equipmentId] != nil
                }
                
                print("✅ Found \(producerRequests.count) valid requests for producer")
                
                DispatchQueue.main.async {
                    self.producerRequests = producerRequests
                    self.producerEquipment = equipment
                    self.equipmentDetails = equipmentDict
                }
            } else {
                print("ℹ️ No equipment found for producer")
                DispatchQueue.main.async {
                    self.producerRequests = []
                    self.producerEquipment = []
                    self.equipmentDetails = [:]
                }
            }
        } catch {
            print("❌ Error decoding equipment: \(error)")
            throw error
        }
    }
    
    func deleteRequest(_ request: Request) async throws {
        // Delete the request from Supabase
        try await supabase.database
            .from("requests")
            .delete()
            .eq("id", value: request.id)
            .execute()
        
        // Update local state
        DispatchQueue.main.async {
            self.producerRequests.removeAll { $0.id == request.id }
        }
    }
    
    func acceptRequest(_ request: Request) async throws {
        print("🔄 Accepting request with ID: \(request.id)")
        
        // Calculate amount based on area and equipment rates
        let equipment = equipmentDetails[request.equipmentId ?? UUID()]
        let amount = (equipment?.pricePerAcre ?? 0.0) * request.area
        print("💰 Calculated amount: \(amount) based on area: \(request.area)")
        
        // Create a new service request
        let serviceRequest = ServiceRequest(
            id: UUID(),  // Generate new UUID
            equipmentname: request.equipmentId ?? UUID(),
            farmerid: request.userId ?? UUID(),
            date: request.requestedDate,
            status: .inProgress,  // Set status as inProgress when accepting
            type: request.type == .coEquip ? .coequip : .individual,
            area: request.area,
            timeslot: request.timeSlot,
            timeperiod: request.timePeriod ?? "",
            location: request.location,
            amount: amount,
            joineduser: []
        )
        
        print("📝 Creating service request with data: \(serviceRequest)")
        
        // Insert into servicerequests table
        try await supabase.database
            .from("servicerequests")
            .insert(serviceRequest)
            .execute()
        
        print("✅ Successfully inserted service request")
        
        print("🗑️ Deleting original request")
        // Delete from requests table
        try await deleteRequest(request)
        
        print("🔄 Refreshing service requests list")
        // Refresh service requests
        try await fetchServiceRequests()
    }
    
    enum ServiceStatus: String, Codable {
        case pending = "pending"
        case inProgress = "inProgress"
        case completed = "completed"
        case cancelled = "cancelled"
        case new = "new"
        case all = "all"
    }
    
    struct MonthlyIncome: Codable {
        let id: UUID
        let producerId: UUID
        let monthYear: String
        let totalAmount: Double
        let completedRequests: Int
        
        enum CodingKeys: String, CodingKey {
            case id
            case producerId = "producer_id"
            case monthYear = "month_year"
            case totalAmount = "total_amount"
            case completedRequests = "completed_requests"
        }
    }
    
    @Published var monthlyIncome: [MonthlyIncome] = []
    
    func fetchMonthlyIncome() async throws {
        guard let currentUser = currentUser else { return }
        
        let response = try await supabase.database
            .from("monthly_income")
            .select()
            .eq("producer_id", value: currentUser.id)
            .execute()
        
        let decoder = JSONDecoder()
        let income = try decoder.decode([MonthlyIncome].self, from: response.data)
        
        DispatchQueue.main.async {
            self.monthlyIncome = income
        }
    }
    
    struct ServiceRequest: Codable {
        let id: UUID
        let equipmentname: UUID
        let farmerid: UUID
        let date: String
        let status: ServiceStatus
        let type: ServiceType
        let area: Double
        let timeslot: TimeSlot
        let timeperiod: String
        let location: String
        let amount: Double
        let joineduser: [UUID]
        
        init(id: UUID, equipmentname: UUID, farmerid: UUID, date: String, status: ServiceStatus, type: ServiceType, area: Double, timeslot: TimeSlot, timeperiod: String, location: String, amount: Double, joineduser: [UUID]) {
            self.id = id
            self.equipmentname = equipmentname
            self.farmerid = farmerid
            self.date = date
            self.status = status
            self.type = type
            self.area = area
            self.timeslot = timeslot
            self.timeperiod = timeperiod
            self.location = location
            self.amount = amount
            self.joineduser = joineduser
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(id, forKey: .id)
            try container.encode(equipmentname, forKey: .equipmentname)
            try container.encode(farmerid, forKey: .farmerid)
            try container.encode(date, forKey: .date)
            try container.encode(status.rawValue, forKey: .status)
            try container.encode(type.rawValue.lowercased(), forKey: .type)
            try container.encode(area, forKey: .area)
            try container.encode(timeslot.rawValue.lowercased(), forKey: .timeslot)
            try container.encode(timeperiod, forKey: .timeperiod)
            try container.encode(location, forKey: .location)
            try container.encode(amount, forKey: .amount)
            try container.encode(joineduser, forKey: .joineduser)
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            id = try container.decode(UUID.self, forKey: .id)
            equipmentname = try container.decode(UUID.self, forKey: .equipmentname)
            farmerid = try container.decode(UUID.self, forKey: .farmerid)
            date = try container.decode(String.self, forKey: .date)
            
            let statusStr = try container.decode(String.self, forKey: .status)
            if let status = ServiceStatus(rawValue: statusStr) {
                self.status = status
            } else {
                // Try with different case variations
                let capitalizedStr = statusStr.capitalized
                if let status = ServiceStatus(rawValue: capitalizedStr) {
                    self.status = status
                } else {
                    throw DecodingError.dataCorruptedError(forKey: .status, in: container, debugDescription: "Invalid status value: \(statusStr)")
                }
            }
            
            let typeStr = try container.decode(String.self, forKey: .type).lowercased()
            if let type = ServiceType(rawValue: typeStr) {
                self.type = type
            } else {
                throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Invalid type value")
            }
            
            area = try container.decode(Double.self, forKey: .area)
            
            let timeslotStr = try container.decode(String.self, forKey: .timeslot).lowercased()
            if let timeslot = TimeSlot(rawValue: timeslotStr) {
                self.timeslot = timeslot
            } else {
                throw DecodingError.dataCorruptedError(forKey: .timeslot, in: container, debugDescription: "Invalid timeslot value")
            }
            
            timeperiod = try container.decode(String.self, forKey: .timeperiod)
            location = try container.decode(String.self, forKey: .location)
            amount = try container.decode(Double.self, forKey: .amount)
            joineduser = try container.decode([UUID].self, forKey: .joineduser)
        }
        
        private enum CodingKeys: String, CodingKey {
            case id
            case equipmentname
            case farmerid
            case date
            case status
            case type
            case area
            case timeslot
            case timeperiod
            case location
            case amount
            case joineduser
        }
    }
    
    @Published var serviceRequests: [ServiceRequest] = []
    
    func fetchServiceRequests() async throws {
        guard let currentUser = currentUser else {
            print("⚠️ No current user found")
            return
        }
        
        print("🔍 Fetching service requests for current user: \(currentUser.id)")
        
        // Get all equipment IDs for this producer
        let equipmentIds = producerEquipment.compactMap { equip in
            return equip.equipmentID.uuidString
        }
        
        print("📱 Producer equipment IDs: \(equipmentIds)")
        
        if !equipmentIds.isEmpty {
            print("🔄 Fetching service requests from database...")
            print("💬 Query parameters: status=inProgress, equipmentIds=\(equipmentIds)")
            let response = try await supabase.database
                .from("servicerequests")
                .select()
                .in("equipmentname", values: equipmentIds)
                .eq("status", value: "inProgress")  // Only fetch in-progress requests
                .execute()
            
            print("📥 Raw response data: \(String(data: response.data, encoding: .utf8) ?? "nil")")
            
            let decoder = JSONDecoder()
            let requests = try decoder.decode([ServiceRequest].self, from: response.data)
            print("✅ Decoded \(requests.count) service requests")
            
            DispatchQueue.main.async {
                self.serviceRequests = requests
            }
        }
    }
    
    private func getTimeSlotForDay(date: Date, slot: TimeSlot) -> ProducerTimeSlot {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: date)
        
        switch slot {
        case .morning:
            components.hour = 6  // 6 AM to 12 PM
            let startTime = calendar.date(from: components) ?? date
            components.hour = 12
            let endTime = calendar.date(from: components) ?? date.addingTimeInterval(6 * 3600)
            return ProducerTimeSlot(startTime: startTime, endTime: endTime)
            
        case .afternoon:
            components.hour = 12  // 12 PM to 6 PM
            let startTime = calendar.date(from: components) ?? date
            components.hour = 18
            let endTime = calendar.date(from: components) ?? date.addingTimeInterval(6 * 3600)
            return ProducerTimeSlot(startTime: startTime, endTime: endTime)
            
        case .evening:
            components.hour = 18  // 6 PM to 10 PM
            let startTime = calendar.date(from: components) ?? date
            components.hour = 22
            let endTime = calendar.date(from: components) ?? date.addingTimeInterval(4 * 3600)
            return ProducerTimeSlot(startTime: startTime, endTime: endTime)
        }
    }
    
    @Published var completedServiceRequests: [ServiceRequest] = []
    
    func fetchCompletedServiceRequests() async throws {
        guard let currentUser = currentUser else {
            print("⚠️ No current user found")
            return
        }
        
        // Get all equipment IDs for this producer
        let equipmentIds = producerEquipment.compactMap { equip in
            return equip.equipmentID.uuidString
        }
        
        if !equipmentIds.isEmpty {
            let response = try await supabase.database
                .from("servicerequests")
                .select()
                .in("equipmentname", values: equipmentIds)
                .eq("status", value: "completed")  // Only fetch completed requests
                .execute()
            
            let decoder = JSONDecoder()
            let requests = try decoder.decode([ServiceRequest].self, from: response.data)
            
            DispatchQueue.main.async {
                self.completedServiceRequests = requests
            }
        }
    }
    
    func completeServiceRequest(_ request: ServiceRequest) async throws {
        // Get the current month and year
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM"
        let monthYear = dateFormatter.string(from: Date())
        
        // Update the service request status to completed
        try await supabase.database
            .from("servicerequests")
            .update(["status": "completed"])
            .eq("id", value: request.id)
            .execute()
        
        // Update monthly income
        print("📊 Updating monthly income with amount: \(request.amount)")
        let response = try await supabase.database
            .from("monthly_income")
            .select()
            .eq("producer_id", value: currentUser?.id ?? "")
            .eq("month_year", value: monthYear)
            .execute()
        
        let decoder = JSONDecoder()
        do {
            let incomeData = try decoder.decode([MonthlyIncome].self, from: response.data)
            
            if let existingIncome = incomeData.first {
                // Update existing record
                print("📊 Updating existing monthly income: Current amount: \(existingIncome.totalAmount), Adding: \(request.amount)")
                
                // Create an update struct to ensure type consistency
                struct MonthlyIncomeUpdate: Encodable {
                    let totalAmount: Double
                    let completedRequests: Int
                    
                    enum CodingKeys: String, CodingKey {
                        case totalAmount = "total_amount"
                        case completedRequests = "completed_requests"
                    }
                }
                
                let update = MonthlyIncomeUpdate(
                    totalAmount: existingIncome.totalAmount + request.amount,
                    completedRequests: existingIncome.completedRequests + 1
                )
                
                try await supabase.database
                    .from("monthly_income")
                    .update(update)
                    .eq("id", value: existingIncome.id)
                    .execute()
            } else {
                // Create new record
                print("📊 Creating new monthly income record with amount: \(request.amount)")
                let newIncome = MonthlyIncome(
                    id: UUID(),
                    producerId: currentUser?.id ?? UUID(),
                    monthYear: monthYear,
                    totalAmount: request.amount,
                    completedRequests: 1
                )
                
                try await supabase.database
                    .from("monthly_income")
                    .insert(newIncome)
                    .execute()
            }
        } catch {
            print("❌ Error processing monthly income: \(error)")
            throw error
        }
        
        // Remove the request from our local list immediately
        DispatchQueue.main.async {
            self.serviceRequests.removeAll { $0.id == request.id }
        }
        
        // Fetch updated monthly income
        try await fetchMonthlyIncome()
    }
    
    func updateEquipment(
        id: UUID,
        name: String,
        type: String,
        capacity: String,
        pricePerHour: Double,
        pricePerAcre: Double,
        location: String,
        modelYear: String,
        mileage: String,
        description: String?
    ) async throws {
        print("🔄 Updating equipment with ID: \(id)")
        
        struct EquipmentUpdate: Encodable {
            let name: String
            let type: String
            let capacity: String
            let pricePerHour: Double  // Match Supabase column names
            let pricePerAcre: Double  // Match Supabase column names
            let location: String
            let modelYear: String      // Match Supabase column names
            let mielage: String
            let description: String
        }
        
        let updates = EquipmentUpdate(
            name: name,
            type: type,
            capacity: capacity,
            pricePerHour: pricePerHour,
            pricePerAcre: pricePerAcre,
            location: location,
            modelYear: modelYear,
            mielage: mileage,
            description: description ?? ""
        )
        
        do {
            let response = try await supabase.database
                .from("equipment")
                .update(updates)
                .eq("equipmentID", value: id.uuidString)  // Convert UUID to string
                .execute()
            
            print("✅ Update response: \(String(data: response.data, encoding: .utf8) ?? "nil")")
            
            // Update local equipment details
            if var equipment = equipmentDetails[id] {
                equipment.name = name
                equipment.type = type
                equipment.capacity = capacity
                equipment.pricePerHour = pricePerHour
                equipment.pricePerAcre = pricePerAcre
                equipment.location = location
                equipment.modelYear = modelYear
                equipment.mielage = mileage
                equipment.description = description
                
                DispatchQueue.main.async {
                    self.equipmentDetails[id] = equipment
                }
            }
        } catch {
            print("❌ Error updating equipment: \(error)")
            throw error
        }
    }
    
    func deleteEquipment(id: UUID) async throws {
        print("🗑 Deleting equipment with ID: \(id)")
        
        try await supabase.database
            .from("equipment")
            .delete()
            .eq("equipmentID", value: id.uuidString)
            .execute()
        
        DispatchQueue.main.async {
            self.equipmentDetails.removeValue(forKey: id)
        }
    }
    
    func calculateMonthlyIncome() -> Double {
        let calendar = Calendar.current
        let now = Date()
        
        // Get the start of the current month
        guard let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now)),
              // Get the start of next month
              let nextMonth = calendar.date(byAdding: .month, value: 1, to: monthStart) else {
            return 0
        }
        
        // Filter completed requests within this month and sum their amounts
        let monthlyTotal = serviceRequests
            .filter { request in
                if let requestDate = ISO8601DateFormatter().date(from: request.date),
                   request.status == .completed {
                    return requestDate >= monthStart && requestDate < nextMonth
                }
                return false
            }
            .reduce(0.0) { total, request in
                total + (request.amount ?? 0)
            }
        
        return monthlyTotal
    }
    
    private func calculateAmount(for request: Request, equipment: Equipment) -> Double {
        let area = Double(request.area)
        let hours = request.timePeriod?.components(separatedBy: " ").first.flatMap { Double($0) } ?? 0.0
        
        if request.type == .coEquip {
            // For co-equipment, use real prices
            return (area * equipment.realPricePerAcre) + (hours * equipment.realPricePerHour)
        } else {
            // For individual equipment, use normal prices
            return (area * equipment.pricePerAcre) + (hours * equipment.pricePerHour)
        }
    }
    
    func uploadEquipmentImage(_ imageData: Data) async throws -> String {
        let fileName = "\(UUID().uuidString).jpg"
        let filePath = "equipment_images/\(fileName)"
        
        // Upload the image to Supabase storage
        try await supabase.storage
            .from("equipment")
            .upload(
                path: filePath,
                file: imageData
            )
        
        // Get the public URL for the uploaded image
        let publicURL = "https://pxuuupiqeipyemluyers.supabase.co/storage/v1/object/public/equipment/\(filePath)"
        
        return publicURL
    }
}
