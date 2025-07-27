//
//  DataModelProducer.swift
//  iKisanApp
//
//  Created by Harsh chauhan on 28/04/25.
//

import Foundation

enum coEquipState: String, Codable {
    case Available
    case Unavailable
}

enum BookingType: String, Codable {
    case coEquip = "Co-Equip"
    case individual = "Individual"
    case prebooking = "Prebooking" // Added to handle "Prebooking" from DB
    case onDemand = "On-Demand"   // Added to handle "On-Demand" from DB
}

enum BookingStatus: String, Codable {
    case pending = "Pending"
    case confirmed = "Confirmed"
    case completed = "Completed"
    case cancelled = "cancelled"
}

enum BookingSource: String, Codable {
    case home = "home"
    case prebooking = "prebooking"
}

struct Booking: Codable, Identifiable {
    let id: UUID
    let userId: UUID?
    let equipmentId: UUID?
    let bookingType: BookingType
    let bookingDate: Date
    let fieldArea: Double
    let status: BookingStatus
    let timeSlot: TimeSlot
    let source: BookingSource
    let latitude: Double?
    let longitude: Double?
    let address: String?
    
    enum CodingKeys: String, CodingKey {
        case id = "bookingID"
        case userId = "userID"
        case equipmentId = "equipmentID"
        case bookingType
        case bookingDate
        case fieldArea
        case status
        case timeSlot
        case source
        case latitude
        case longitude
        case address
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        userId = try container.decodeIfPresent(UUID.self, forKey: .userId)
        equipmentId = try container.decodeIfPresent(UUID.self, forKey: .equipmentId)
        bookingType = try container.decode(BookingType.self, forKey: .bookingType)
        
        // Decode the timestamp string to Date
        let dateString = try container.decode(String.self, forKey: .bookingDate)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        if let date = formatter.date(from: dateString) {
            bookingDate = date
        } else {
            throw DecodingError.dataCorruptedError(forKey: .bookingDate,
                                                  in: container,
                                                  debugDescription: "Date string does not match expected format")
        }
        
        fieldArea = try container.decode(Double.self, forKey: .fieldArea)
        status = try container.decode(BookingStatus.self, forKey: .status)
        timeSlot = try container.decode(TimeSlot.self, forKey: .timeSlot)
        source = try container.decode(BookingSource.self, forKey: .source)
        latitude = try container.decodeIfPresent(Double.self, forKey: .latitude)
        longitude = try container.decodeIfPresent(Double.self, forKey: .longitude)
        address = try container.decodeIfPresent(String.self, forKey: .address)
    }
}

enum TimeSlot: String, Codable {
    case morning = "morning"
    case afternoon = "afternoon"
    case evening = "evening"
    
    // Custom decoder to handle capitalized input
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self).lowercased()
        
        switch value {
        case "morning":
            self = .morning
        case "afternoon":
            self = .afternoon
        case "evening":
            self = .evening
        default:
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Cannot initialize TimeSlot from invalid String value \(value)"
            )
        }
    }
}

enum RequestType: String, Codable {
    case myRequest = "myRequest"
    case joinedRequest = "acceptedRequest"
}

struct MonthlyIncome: Codable, Identifiable {
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

struct Equipment: Codable, Identifiable {
    let id: UUID
    var equipmentImage: String
    var name: String
    var type: String
    var capacity: String
    var availabilityStartDate: Date
    var availabilityEndDate: Date
    var pricePerHour: Double
    var realPricePerHour: Double
    var pricePerAcre: Double
    var realPricePerAcre: Double
    var providerID: UUID
    var rating: Double
    var location: String
    var coEquipDetail: coEquipState
    var modelYear: String
    var mielage: String
    var description: String?
    var isRecommended: Bool?
    var providerName: String?
    var preBookingStatus: String?
    
    enum CodingKeys: String, CodingKey {
        case id = "equipmentID"
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

struct Request: Codable, Identifiable {
    let id: UUID
    let userId: UUID?
    let equipmentId: UUID?
    let requestedDate: String
    var status: BookingStatus
    let type: BookingType
    let area: Double
    let timeSlot: TimeSlot
    let timePeriod: String?
    let location: String
    let typeOfRequest: RequestType
    
    
    var date: Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return formatter.date(from: requestedDate)
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId
        case equipmentId
        case requestedDate
        case status
        case type
        case area
        case timeSlot
        case timePeriod
        case location
        case typeOfRequest
       
    }
    }


struct Producer: Codable {
    let id: UUID
    var name: String
    let email: String
    var phone: String?
    var location: String?
    let rating: Double?
    let profileimage: String?
    let equipments: [String]?
    var accountNo: String?
    var ifcsCode: String?
}

struct ServiceRequests: Codable {
    let id: UUID
    var farmerid: UUID
    var equipmentname: UUID
    var amount: Double
    let date: String
    var status: ServiceStatus
    var type: ServiceType
    var area: Double
    var timeslot: TimeSlot
    var timeperiod: String
    var location: String
    
    var dateObject: Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return formatter.date(from: date)
    }
}

enum ServiceType: String, Codable {
    case coequip = "coequip"
    case individual = "individual"
}

struct ProducerTimeSlot: Codable {
    let startTime: Date
    let endTime: Date
}

enum ServiceStatus: String, Codable {
    case all = "all"
    case pending = "pending"
    case inProgress = "inProgress"
    case completed = "completed"
    case cancelled = "cancelled"
    case new = "new"
}

// Session management
class ProducerSession {
    static let shared = ProducerSession()
    private let defaults = UserDefaults.standard
    
    private let currentProducerKey = "currentProducer"
    private let authTokenKey = "authToken"
    
    private init() {}
    
    var currentProducer: Producer? {
        get {
            guard let data = defaults.data(forKey: currentProducerKey) else { return nil }
            return try? JSONDecoder().decode(Producer.self, from: data)
        }
        set {
            if let producer = newValue,
               let data = try? JSONEncoder().encode(producer) {
                defaults.set(data, forKey: currentProducerKey)
            } else {
                defaults.removeObject(forKey: currentProducerKey)
            }
        }
    }
    
    var authToken: String? {
        get { defaults.string(forKey: authTokenKey) }
        set {
            if let token = newValue {
                defaults.set(token, forKey: authTokenKey)
            } else {
                defaults.removeObject(forKey: authTokenKey)
            }
        }
    }
    
    func clearSession() {
        currentProducer = nil
        authToken = nil
    }
    
    var isLoggedIn: Bool {
        return currentProducer != nil && authToken != nil
    }
}
